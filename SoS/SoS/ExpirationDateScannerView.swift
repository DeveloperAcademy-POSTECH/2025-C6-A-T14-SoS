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
                    let dates = extractExpirationDates(from: text)
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
    
    // MARK: - Helper
    private func extractExpirationDates(from text: String) -> [String] {
        var results: [String] = []
        let patterns: [String] = [
            // 기본 포맷
            #"\d{4}\s*\.\s*\d{2}\s*\.\s*\d{2}"#,
            #"\d{2}\s*\.\s*\d{2}\s*\.\s*\d{2}"#,
            #"\d{4}\s*-\s*\d{2}\s*-\s*\d{2}"#,
            #"\d{2}\s*-\s*\d{2}\s*-\s*\d{2}"#,
            #"\d{4}\s*/\s*\d{2}\s*/\s*\d{2}"#,
            #"\d{2}\s*/\s*\d{2}\s*/\s*\d{2}"#,
            #"\d{4}\s*\s\d{2}\s*\s\d{2}"#,
            #"\d{2}\s*\s\d{2}\s*\s\d{2}"#,
            
            // OCR 변형 (·, －, ~ 등)
            #"\d{4}\s*[·•－~]\s*\d{2}\s*[·•－~]\s*\d{2}"#,
            #"\d{2}\s*[·•－~]\s*\d{2}\s*[·•－~]\s*\d{2}"#,
            #"\d{4}\s*[·•~]\s*\d{2}\s*[·•~]\s*\d{2}"#,
            #"\d{2}\s*[·•~]\s*\d{2}\s*[·•~]\s*\d{2}"#,

            // 한글 포맷
            #"\d{4}\s*년\s*\d{1,2}\s*월\s*\d{1,2}\s*일"#,
            #"\d{2}\s*년\s*\d{1,2}\s*월\s*\d{1,2}\s*일"#,
            #"\d{4}\s*년\s*\d{1,2}\s*월\s*\d{1,2}"#,
            #"\d{4}\s*년\s*\d{1,2}\s*월"#,
            #"\d{2}\s*년\s*\d{1,2}\s*월"#,

            // 영어 포맷
            #"\d{1,2}\s*[A-Za-z]{3,9}\s*\d{2,4}"#,      // 25 JUN 25, 25 June 2025
            #"[A-Za-z]{3,9}\s*\d{1,2},?\s*\d{2,4}"#,    // June 25 2025, Jun 25, 25

            // 월/일/연도 포맷
            #"\d{2}\s*/\s*\d{2}\s*/\s*\d{4}"#,
            #"\d{2}\s*-\s*\d{2}\s*-\s*\d{4}"#,
            #"\d{2}\s*\.\s*\d{2}\s*\.\s*\d{4}"#,
            #"\d{2}\s*[·•]\s*\d{2}\s*[·•]\s*\d{4}"#,

            // 일/월/연도 포맷
            #"\d{2}\s*/\s*\d{2}\s*/\s*\d{2,4}"#,
            #"\d{2}\s*-\s*\d{2}\s*-\s*\d{2,4}"#,
            #"\d{2}\s*\.\s*\d{2}\s*\.\s*\d{2,4}"#,

            // 연결된 형태 (예: 20250630, 250630)
            #"\b\d{8}\b"#,
            #"\b\d{6}\b"#,

            // 접두사 포함: EXP, BEST BEFORE, USE BY, BBE
            #"(?i)(EXP|EXPIRE|EXPIRES|EXPIRED)\s*:?\s*\d{4}\s*[-./·]\s*\d{2}\s*[-./·]\s*\d{2}"#,
            #"(?i)(EXP|EXPIRE|EXPIRES|EXPIRED)\s*:?\s*\d{2}\s*[-./·]\s*\d{2}\s*[-./·]\s*\d{2}"#,
            #"(?i)(BEST\s*BEFORE|USE\s*BY|BBE)\s*:?\s*\d{4}\s*[-./·]\s*\d{2}\s*[-./·]\s*\d{2}"#,
            #"(?i)(BEST\s*BEFORE|USE\s*BY|BBE)\s*:?\s*\d{2}\s*[-./·]\s*\d{2}\s*[-./·]\s*\d{2}"#,

            // 접두사 + 붙은 날짜 (공백 없이)
            #"(?i)(EXP|EXPIRE|EXPIRES|EXPIRED)\s*:?\s*\d{8}"#,
            #"(?i)(EXP|EXPIRE|EXPIRES|EXPIRED)\s*:?\s*\d{6}"#,
            #"(?i)(BBE|BESTBEFORE|USEBY)\s*:?\s*\d{8}"#,
            #"(?i)(BBE|BESTBEFORE|USEBY)\s*:?\s*\d{6}"#,

            // 날짜 범위 표기 (~, -, to, →)
            #"\d{4}\s*[./-]\s*\d{2}\s*[./-]\s*\d{2}\s*[~→-]\s*\d{4}\s*[./-]\s*\d{2}\s*[./-]\s*\d{2}"#,
            #"\d{2}\s*[./-]\s*\d{2}\s*[./-]\s*\d{2}\s*[~→-]\s*\d{2}\s*[./-]\s*\d{2}\s*[./-]\s*\d{2}"#,
            #"\d{4}\s*년\s*\d{1,2}\s*월\s*\d{1,2}\s*일\s*[~→-]\s*\d{4}\s*년\s*\d{1,2}\s*월\s*\d{1,2}\s*일"#,

            // 혼합형 구분자
            #"\d{4}\s*[./·-]\s*\d{1,2}\s*[./·-]\s*\d{1,2}"#,
            #"\d{2}\s*[./·-]\s*\d{1,2}\s*[./·-]\s*\d{1,2}"#,
            #"\d{4}\s*[./·]\s*\d{1,2}\s*[-]\s*\d{1,2}"#,
            #"\d{4}\s*[-]\s*\d{1,2}\s*[./]\s*\d{1,2}"#,

            // 영어와 숫자 조합
            #"(?i)(EXP|BEST\s*BEFORE|USE\s*BY)\s*[A-Za-z]{3}\s*\d{1,2},?\s*\d{2,4}"#,
            #"(?i)(EXP|USE\s*BY)\s*\d{1,2}\s*[A-Za-z]{3,9}\s*\d{2,4}"#,

            // 기타 특수 케이스
            #"\b\d{4}[年년]\d{1,2}[月월]\d{1,2}[日일]?\b"#,
            #"\b\d{2}[年년]\d{1,2}[月월]\d{1,2}[日일]?\b"#,
            #"[A-Za-z]{3}\s*\d{2}\s*[’']?\s*\d{2,4}"#,
            #"[A-Za-z]{3}\.?\s*\d{1,2}\s*[’']?\s*\d{2,4}"#,
            #"(?:MFD|MFG|MANUFACTURED)\s*:?\s*\d{4}\s*[./-]\s*\d{2}\s*[./-]\s*\d{2}"#,
            #"(?:MFD|MFG|MANUFACTURED)\s*:?\s*\d{2}\s*[./-]\s*\d{2}\s*[./-]\s*\d{2}"#,
            #"(\d{2,4})\s*[년年.·/-]\s*(\d{1,2})\s*[월月.·/-]\s*(\d{1,2})\s*[일日]?"#,
        ]

        for pattern in patterns {
            results.append(contentsOf: extractMatches(from: text, pattern: pattern))
        }
        return Array(Set(results)).sorted()
    }
    
    private func extractMatches(from text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        return matches.compactMap {
            Range($0.range, in: text).map { String(text[$0]) }
        }
    }
}

// MARK: - Result View
struct ExpirationResultView: View {
    let expirationDates: [String]
    
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

// MARK: - DataScanner Wrapper
struct LiveTextScanner: UIViewControllerRepresentable {
    var languages: [String] = ["ko", "en"]
    var onRecognized: (String) -> Void
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let types: Set<DataScannerViewController.RecognizedDataType> = [
            .text(languages: languages)
        ]
        
        let vc = DataScannerViewController(
            recognizedDataTypes: types,
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        
        vc.delegate = context.coordinator
        
        DispatchQueue.main.async {
            do {
                try vc.startScanning()
            } catch {
                print("⚠️ DataScanner 시작 실패:", error)
            }
        }
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: LiveTextScanner
        
        init(_ parent: LiveTextScanner) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController,
                        didAdd addedItems: [RecognizedItem],
                        allItems: [RecognizedItem]) {
            var fullText = ""
            for item in allItems {
                if case let .text(text) = item {
                    fullText += text.transcript + " "
                }
            }
            
            if !fullText.isEmpty {
                DispatchQueue.main.async {
                    self.parent.onRecognized(fullText)
                }
            }
        }
    }
}
