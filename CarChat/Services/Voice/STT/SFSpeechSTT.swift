import Foundation
import Speech
import AVFoundation

@MainActor
final class SFSpeechSTT: STTEngine {
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private var transcriptContinuation: AsyncStream<VoiceTranscript>.Continuation?
    private var audioLevelContinuation: AsyncStream<Float>.Continuation?

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

        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: recordingFormat,
            block: makeAudioTapBlock(
                request: recognitionRequest,
                audioLevelContinuation: audioLevelContinuation
            )
        )

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            cleanupRecognition()
            throw error
        }

        isListening = true

        let cleanup: @Sendable () -> Void = { [weak self] in
            Task { @MainActor [weak self] in
                self?.cleanupRecognition()
            }
        }
        let transcriptContinuation = self.transcriptContinuation

        recognitionTask = speechRecognizer.recognitionTask(
            with: recognitionRequest,
            resultHandler: makeRecognitionResultHandler(
                transcriptContinuation: transcriptContinuation,
                cleanup: cleanup
            )
        )
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

private func makeAudioTapBlock(
    request: SFSpeechAudioBufferRecognitionRequest,
    audioLevelContinuation: AsyncStream<Float>.Continuation?
) -> AVAudioNodeTapBlock {
    return { buffer, _ in
        request.append(buffer)

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

private func recognitionResultHandler(
    transcriptContinuation: AsyncStream<VoiceTranscript>.Continuation?,
    result: SFSpeechRecognitionResult?,
    error: (any Error)?,
    cleanup: @escaping @Sendable () -> Void
) {
    if let result {
        transcriptContinuation?.yield(
            VoiceTranscript(
                text: result.bestTranscription.formattedString,
                isFinal: result.isFinal,
                role: .user
            )
        )
    }

    if error != nil {
        transcriptContinuation?.yield(
            VoiceTranscript(text: "", isFinal: true, role: .user)
        )
        cleanup()
    } else if result?.isFinal == true {
        cleanup()
    }
}

private func makeRecognitionResultHandler(
    transcriptContinuation: AsyncStream<VoiceTranscript>.Continuation?,
    cleanup: @escaping @Sendable () -> Void
) -> (SFSpeechRecognitionResult?, (any Error)?) -> Void {
    return { result, error in
        recognitionResultHandler(
            transcriptContinuation: transcriptContinuation,
            result: result,
            error: error,
            cleanup: cleanup
        )
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
