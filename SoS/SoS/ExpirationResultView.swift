import SwiftUI
import AVFoundation
import UIKit

struct ExpirationResultView: View {
    let expirationDates: [String]
    @AppStorage("isTTSEnabled") private var isTTSEnabled = false
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📅 인식된 유통기한")
                .font(.title2)
                .fontWeight(.semibold)
                .accessibilityHidden(true)
            
            ForEach(expirationDates, id: \.self) { date in
                let expired = isExpired(date)
                
                HStack {
                    Text(date)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                    Spacer()
                    Text(expired ? "⚠️ 만료" : "✓ 유효")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(expired ? .red : .green)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(date), \(expired ? "만료됨" : "유효함")")
                .accessibilityHint("이 유통기한은 \(expired ? "이미 지났습니다" : "아직 사용 가능합니다").")
            }
            Spacer()
        }
        .padding()
        .navigationTitle("인식 결과")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // VoiceOver 켜져 있으면 VoiceOver로 알리고,
            // 아니면 TTSManager로 직접 읽음
            if voiceOverEnabled {
                let summary = expirationDates.map {
                    "\(isExpired($0) ? "만료" : "유효") 상태의 \($0)"
                }.joined(separator: ", ")
                UIAccessibility.post(notification: .announcement,
                                     argument: "유통기한 인식 결과입니다. \(summary)")
            } else if isTTSEnabled {
                TTSManager.shared.speak("유통기한 인식 결과입니다.")
                for date in expirationDates {
                    if isExpired(date) {
                        TTSManager.shared.speak("\(date)은 만료되었습니다.")
                    } else {
                        TTSManager.shared.speak("\(date)은 아직 유효합니다.")
                    }
                }
            }
        }
        // 메인뷰로 되돌아갈 때 음성출력 중단
        .onDisappear {
            TTSManager.shared.stop()
        }
    }
    
    private func isExpired(_ dateString: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        
        var normalizedDate = dateString
        if dateString.contains("-") {
            normalizedDate = dateString.replacingOccurrences(of: "-", with: ".")
        } else if dateString.contains("/") {
            normalizedDate = dateString.replacingOccurrences(of: "/", with: ".")
        }
        
        let components = normalizedDate.split(separator: ".")
        if components.count == 3 && components[0].count == 2 {
            normalizedDate = "20\(normalizedDate)"
        }
        
        guard let date = dateFormatter.date(from: normalizedDate) else { return false }
        return date < Date()
    }
}
