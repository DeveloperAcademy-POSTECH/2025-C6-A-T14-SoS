import Foundation
import SwiftUI
import AVFoundation
import UIKit

/// VoiceOver와 중복되지 않도록 안전하게 설계
final class TTSManager: NSObject, ObservableObject {
    static let shared = TTSManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    @AppStorage("isTTSEnabled") private var isTTSEnabled = true
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        
        // VoiceOver 상태 변화 감지 → TTS 자동 정지
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleVoiceOverChange),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
    }
    
    // MARK: - VoiceOver 상태 감지
    @objc private func handleVoiceOverChange() {
        if UIAccessibility.isVoiceOverRunning {
            stop()
        }
    }
    
    // MARK: - 공개 메서드
    func speak(_ text: String) {
        // 사용자가 TTS 끔 or VoiceOver 켜짐 → 실행 안 함
        guard isTTSEnabled, !UIAccessibility.isVoiceOverRunning else { return }
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("⚠️ Audio session error: \(error.localizedDescription)")
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        utterance.rate = 0.48
        utterance.preUtteranceDelay = 0.1
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}

// MARK: - Delegate
extension TTSManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
