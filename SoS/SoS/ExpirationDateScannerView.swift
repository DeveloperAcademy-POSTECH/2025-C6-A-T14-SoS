//
//  ExpirationDateScannerView.swift
//  SoS
//
//  Created by oliver on 10/14/25.
//

import SwiftUI
import VisionKit

struct ExpirationDateScannerView: View {
    @State private var recognizedText: String = ""
    @State private var expirationDates: [String] = []
    @AppStorage("isTTSEnabled") private var isTTSEnabled = true
    @State private var showInfoAlert = false
    @State private var navigateToResult = false
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 카메라 스캐너
                LiveTextScanner { text in
                    recognizedText = text
                    
                    // 유통기한 형식 추출
                    let dates = ExpirationDateExtractor.extract(from: text)
                    if !dates.isEmpty {
                        expirationDates = dates
                        navigateToResult = true
                        if voiceOverEnabled {
                            UIAccessibility.post(
                                notification: .announcement,
                                argument: "유통기한을 인식했습니다."
                            )
                        }
                        
                    }
                }
                .ignoresSafeArea()
                .accessibilityHidden(true) // 카메라 프리뷰는 읽지 않음
                
                // 실시간 인식된 텍스트 오버레이
                if !recognizedText.isEmpty {
                    VStack {
                        ScrollView {
                            Text(recognizedText)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .background(Color.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                        .frame(maxHeight: 180)
                        
                        Spacer()
                    }
                }
                
                // 안내 오버레이
                VStack {
                    Spacer()
                    Text("📸 유통기한을 카메라에 비춰주세요")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.bottom, 50)
                        .accessibilityLabel("유통기한 안내문")
                        .accessibilityHint("카메라를 제품의 유통기한 부분에 비추면 자동으로 인식됩니다.")
                }
            }
            .navigationTitle("유통기한 스캐너")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isTTSEnabled.toggle()
                        // VoiceOver가 켜져 있으면 TTS를 출력하지 않음
                        if isTTSEnabled && !voiceOverEnabled {
                            TTSManager.shared.speak("음성 안내 기능이 켜졌습니다.")
                        } else {
                            TTSManager.shared.stop()
                        }
                    } label: {
                        if isTTSEnabled {
                            Image(systemName: "waveform")
                                .foregroundStyle(.white)
                        } else {
                            Image(systemName: "waveform.slash")
                                .foregroundStyle(.white)
                        }
                    }
                    .accessibilityLabel(isTTSEnabled ? "TTS 끄기 버튼" : "TTS 켜기 버튼")
                    .accessibilityHint("음성 안내 기능을 켜거나 끌 수 있습니다.")
                    .accessibilityAddTraits(.isButton)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showInfoAlert = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel("사용 방법 버튼")
                    .accessibilityHint("유통기한 인식 방법을 볼 수 있습니다.")
                    .accessibilityAddTraits(.isButton)
                }
            }
            .alert("사용 방법", isPresented: $showInfoAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("""
                제품의 유통기한을 카메라에 비춰주세요.
                
                인식 가능한 형식:
                • 2024.12.31
                • 24.12.31
                • 2024-12-31
                • 2024/12/31
                """)
            }
            .onAppear {
                if voiceOverEnabled {
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: "유통기한 스캐너 화면입니다. 제품의 유통기한 부분을 카메라에 비춰주세요."
                    )
                }
//                recognizedText = ""
//                expirationDates = []
//                navigateToResult = false
            }
            // 결과 화면으로 이동
            .navigationDestination(isPresented: $navigateToResult) {
                ExpirationResultView(expirationDates: expirationDates)
            }
            // VoiceOver 상태변화시, TTS 미출력
            .onChange(of: voiceOverEnabled) { newValue in
                if newValue {
                    TTSManager.shared.stop()
                }
            }
            // 메인뷰(스캐너)를 벗어날 때도 TTS 출력 중단
            .onDisappear {
                TTSManager.shared.stop()
            }
        }
    }
}

#Preview {
    ExpirationDateScannerView()
}
