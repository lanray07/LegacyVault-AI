import AVFoundation
import Combine
import Foundation
import Speech
import SwiftUI

final class SpeechRecognitionService: ObservableObject {
    @Published var transcript = ""
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var isTranscribing = false
    @Published var lastError: String?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_GB"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
            }
        }
    }

    func startTranscribing() throws {
        recognitionTask?.cancel()
        recognitionTask = nil
        transcript = ""
        lastError = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isTranscribing = true

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result {
                    self?.transcript = result.bestTranscription.formattedString
                }

                if let error {
                    self?.lastError = error.localizedDescription
                    self?.stopTranscribing()
                } else if result?.isFinal == true {
                    self?.stopTranscribing()
                }
            }
        }
    }

    func stopTranscribing() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
        isTranscribing = false
    }
}

final class VoiceRecordingService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var currentURL: URL?
    @Published var durationSeconds: Double = 0

    private var recorder: AVAudioRecorder?

    func startRecording() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true)

        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("legacy-voice-\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.delegate = self
        recorder.record()
        self.recorder = recorder
        currentURL = url
        durationSeconds = 0
        isRecording = true
    }

    func stopRecording() -> Double {
        durationSeconds = recorder?.currentTime ?? 0
        recorder?.stop()
        recorder = nil
        isRecording = false
        return durationSeconds
    }
}

final class WaveformAnimationManager: ObservableObject {
    @Published var levels: [CGFloat] = Array(repeating: 0.22, count: 32)

    private var timer: Timer?

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.09, repeats: true) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.levels = self.levels.map { _ in CGFloat.random(in: 0.18...1.0) }
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        levels = Array(repeating: 0.22, count: 32)
    }
}
