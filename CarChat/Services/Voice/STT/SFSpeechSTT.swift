import Foundation
import Speech
import AVFoundation

@MainActor
final class SFSpeechSTT: STTEngine {
    private let speechRecognizer: SFSpeechRecognizer
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private var transcriptContinuation: AsyncStream<VoiceTranscript>.Continuation?
    nonisolated(unsafe) private var audioLevelContinuation: AsyncStream<Float>.Continuation?

    private(set) var isListening = false

    let transcriptStream: AsyncStream<VoiceTranscript>
    let audioLevelStream: AsyncStream<Float>

    init(locale: Locale = .current) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer()!

        var transcriptCont: AsyncStream<VoiceTranscript>.Continuation!
        self.transcriptStream = AsyncStream { transcriptCont = $0 }
        self.transcriptContinuation = transcriptCont

        var audioLevelCont: AsyncStream<Float>.Continuation!
        self.audioLevelStream = AsyncStream { audioLevelCont = $0 }
        self.audioLevelContinuation = audioLevelCont
    }

    func startListening() async throws {
        guard !isListening else { return }
        guard speechRecognizer.isAvailable else {
            throw STTError.speechRecognizerUnavailable
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else {
            throw STTError.requestCreationFailed
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.processAudioLevel(buffer: buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isListening = true

        recognitionTask = speechRecognizer.recognitionTask(
            with: recognitionRequest
        ) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let transcript = VoiceTranscript(
                    text: result.bestTranscription.formattedString,
                    isFinal: result.isFinal,
                    role: .user
                )
                self.transcriptContinuation?.yield(transcript)
            }

            if error != nil || result?.isFinal == true {
                Task { @MainActor in
                    self.cleanupRecognition()
                }
            }
        }
    }

    func stopListening() async {
        cleanupRecognition()
    }

    private func cleanupRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
    }

    nonisolated private func processAudioLevel(buffer: AVAudioPCMBuffer) {
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

        audioLevelContinuation?.yield(normalized)
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
