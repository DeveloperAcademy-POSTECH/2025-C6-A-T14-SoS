import SwiftUI
import AVFoundation

struct ExpirationResultView: View {
    let expirationDates: [String]
    @AppStorage("isTTSEnabled") private var isTTSEnabled = false
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📅 인식된 유통기한")
                .font(.title2)
                .fontWeight(.semibold)
            
            ForEach(expirationDates, id: \.self) { date in
                HStack {
                    Text(date)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                    
                    Spacer()
                    
                    if isExpired(date) {
                        Text("⚠️ 만료")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.red)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    } else {
                        Text("✓ 유효")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.green)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("인식 결과")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // TTS 켜짐 + VoiceOver 꺼짐일 때만 음성 출력
            guard isTTSEnabled && !voiceOverEnabled else { return }
            // 유통기한 결과 음성출력 양식(내용)
            TTSManager.shared.speak("유통기한 인식 결과입니다.")
            
            for date in expirationDates {
                if isExpired(date) {
                    TTSManager.shared.speak("\(date)은 만료되었습니다.")
                } else {
                    TTSManager.shared.speak("\(date)은 아직 유효합니다.")
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
