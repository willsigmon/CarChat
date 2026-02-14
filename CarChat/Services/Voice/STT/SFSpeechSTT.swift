import Foundation
import Speech
import AVFoundation

@MainActor
final class SFSpeechSTT: STTEngine {
    private let speechRecognizer: SFSpeechRecognizer?
    nonisolated(unsafe) private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    nonisolated(unsafe) private var transcriptContinuation: AsyncStream<VoiceTranscript>.Continuation?
    nonisolated(unsafe) private var audioLevelContinuation: AsyncStream<Float>.Continuation?

    private(set) var isListening = false

    let transcriptStream: AsyncStream<VoiceTranscript>
    let audioLevelStream: AsyncStream<Float>

    init(locale: Locale = .current) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
            ?? SFSpeechRecognizer()

        var transcriptCont: AsyncStream<VoiceTranscript>.Continuation!
        self.transcriptStream = AsyncStream { transcriptCont = $0 }
        self.transcriptContinuation = transcriptCont

        var audioLevelCont: AsyncStream<Float>.Continuation!
        self.audioLevelStream = AsyncStream { audioLevelCont = $0 }
        self.audioLevelContinuation = audioLevelCont
    }

    func startListening() async throws {
        guard !isListening else { return }

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw STTError.speechRecognizerUnavailable
        }

        guard AVAudioApplication.shared.recordPermission == .granted else {
            throw STTError.notAuthorized
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else {
            throw STTError.requestCreationFailed
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Capture values directly — the tap callback runs on the audio thread,
        // NOT the MainActor, so we cannot access `self` (which is @MainActor).
        let request = recognitionRequest
        let levelContinuation = audioLevelContinuation

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)

            // Inline audio level processing (avoids going through @MainActor self)
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameCount = Int(buffer.frameLength)
            guard frameCount > 0 else { return }
            var sum: Float = 0
            for i in 0..<frameCount {
                let sample = channelData[i]
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(frameCount))
            let db = 20 * log10(max(rms, 0.000001))
            let normalized = max(0, min(1, (db + 60) / 60))
            levelContinuation?.yield(normalized)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            cleanupRecognition()
            throw error
        }

        isListening = true

        // Capture the continuation directly — recognitionTask callback runs
        // on an arbitrary queue, not the MainActor.
        let transcriptCont = transcriptContinuation

        recognitionTask = speechRecognizer.recognitionTask(
            with: recognitionRequest
        ) { [weak self] result, error in
            if let result {
                let transcript = VoiceTranscript(
                    text: result.bestTranscription.formattedString,
                    isFinal: result.isFinal,
                    role: .user
                )
                transcriptCont?.yield(transcript)
            }

            if error != nil {
                transcriptCont?.yield(
                    VoiceTranscript(text: "", isFinal: true, role: .user)
                )
                Task { @MainActor [weak self] in
                    self?.cleanupRecognition()
                }
            } else if result?.isFinal == true {
                Task { @MainActor [weak self] in
                    self?.cleanupRecognition()
                }
            }
        }
    }

    func stopListening() async {
        cleanupRecognition()
    }

    private func cleanupRecognition() {
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        isListening = false
    }

}

enum STTError: LocalizedError {
    case speechRecognizerUnavailable
    case requestCreationFailed
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .speechRecognizerUnavailable: "Speech recognizer is not available"
        case .requestCreationFailed: "Failed to create recognition request"
        case .notAuthorized: "Speech recognition not authorized"
        }
    }
}
