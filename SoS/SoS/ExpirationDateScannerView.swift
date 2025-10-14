//
//  ExpirationDateScannerView.swift
//  SoS
//
//  Created by oliver on 10/14/25.
//

import SwiftUI
import VisionKit

// MARK: - Main View
struct ExpirationDateScannerView: View {
    @State private var recognizedText: String = ""
    @State private var expirationDates: [String] = []
    @State private var showAlert = false
    @State private var navigateToResult = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 카메라 스캐너
                LiveTextScanner { text in
                    recognizedText = text
                    
                    // 유통기한 형식 추출
                    let dates = ExpirationDateExtractor.extract(from: text) //ExpirationDateExtrator를 분리 하였음.
                    if !dates.isEmpty {
                        expirationDates = dates
                        navigateToResult = true
                    }
                }
                .ignoresSafeArea()
                
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
                }
            }
            .navigationTitle("유통기한 스캐너")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAlert = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.white)
                    }
                }
            }
            .alert("사용 방법", isPresented: $showAlert) {
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
            // 결과 화면으로 이동
            .navigationDestination(isPresented: $navigateToResult) {
                ExpirationResultView(expirationDates: expirationDates)
            }
        }
    }
}
