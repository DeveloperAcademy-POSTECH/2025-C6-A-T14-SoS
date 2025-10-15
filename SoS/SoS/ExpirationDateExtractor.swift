//
//  ExpirationDateExtractor.swift
//  SoS
//
//  Created by 서세린 on 10/14/25.
//

import Foundation

struct ExpirationDateExtractor {
    static func extract(from text: String) -> [String] {
        var results: [String] = []
        let patterns: [String] = [
            // 점(.) 구분자: 2025.10.15, 25.10.15
            #"\d{4}\s*\.\s*\d{2}\s*\.\s*\d{2}"#, // 4자리 연도
            #"\d{2}\s*\.\s*\d{2}\s*\.\s*\d{2}"#, // 2자리 연도
            #"\d{4}\s*\.\s*\d{2}"#, // 2025.10 (년/월)
            #"\d{2}\s*\.\s*\d{2}"#, // 25.10 (년/월)
            #"\d{2}\s*\.\s*\d{2}"#, // 10.15 (월/일)
            
            // 하이픈(-) 구분자: 2025-10-15, 25-10-15
            #"\d{4}\s*-\s*\d{2}\s*-\s*\d{2}"#, // 4자리 연도
            #"\d{2}\s*-\s*\d{2}\s*-\s*\d{2}"#, // 2자리 연도
            #"\d{4}\s*-\s*\d{2}"#, // 2025-10 (년/월)
            #"\d{2}\s*-\s*\d{2}"#, // 25-10 (년/월)
            #"\d{2}\s*-\s*\d{2}"#, // 10-15 (월/일)
            
            // 슬래시(/) 구분자: 2025/10/15, 25/10/15
            #"\d{4}\s*/\s*\d{2}\s*/\s*\d{2}"#, // 4자리 연도
            #"\d{2}\s*/\s*\d{2}\s*/\s*\d{2}"#, // 2자리 연도
            #"\d{4}\s*/\s*\d{2}"#, // 2025/10 (년/월)
            #"\d{2}\s*/\s*\d{2}"#, // 25/10 (년/월)
            #"\d{2}\s*/\s*\d{2}"#, // 10/15 (월/일)
            
            // OCR 변형 구분자(·, •, －, ~): 2025·10·15, 25•10•15, 2025－10－15, 25~10~15
            #"\d{4}\s*[·•－~]\s*\d{2}\s*[·•－~]\s*\d{2}"#, // 4자리 연도
            #"\d{2}\s*[·•－~]\s*\d{2}\s*[·•－~]\s*\d{2}"#, // 2자리 연도
            #"\d{4}\s*[·•－~]\s*\d{2}"#, // 2025·10 (년/월)
            #"\d{2}\s*[·•－~]\s*\d{2}"#, // 25•10 (년/월)
            #"\d{2}\s*[·•－~]\s*\d{2}"#, // 10~15 (월/일)
            
            // 한글 포맷: 2025년 10월 15일, 25년 10월 15일
            #"\d{4}\s*년\s*\d{2}\s*월\s*\d{2}\s*일"#, // 4자리 연도
            #"\d{2}\s*년\s*\d{2}\s*월\s*\d{2}\s*일"#, // 2자리 연도
            #"\d{4}\s*년\s*\d{2}\s*월"#, // 2025년 10월 (년/월)
            #"\d{2}\s*년\s*\d{2}\s*월"#, // 25년 10월 (년/월)
            #"\d{2}\s*월\s*\d{2}\s*일"#, // 10월 15일 (월/일)
            
            // 혼합형 구분자: 2025.10-15, 2025-10.15, 25.10-15 등
            #"\d{4}\s*[./·-]\s*\d{2}\s*[./·-]\s*\d{2}"#, // 4자리 연도
            #"\d{2}\s*[./·-]\s*\d{2}\s*[./·-]\s*\d{2}"#, // 2자리 연도
            #"\d{4}\s*[./·-]\s*\d{2}"#, // 2025.10, 2025-10 등 (년/월)
            #"\d{2}\s*[./·-]\s*\d{2}"#, // 25.10, 25-10 등 (년/월)
            #"\d{2}\s*[./·-]\s*\d{2}"#, // 10.15, 10-15 등 (월/일)
        ]
        
        for pattern in patterns {
            results.append(contentsOf: extractMatches(from: text, pattern: pattern))
        }
        
        let normalized = results.map { normalizeDate($0) }
        
        return Array(Set(normalized)).sorted()
    }
    
    /// regex와 매칭되는 결과를 찾는 함수
    private static func extractMatches(from text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        return matches.compactMap {
            Range($0.range, in: text).map { String(text[$0]) }
        }
    }
    
    /// 문자열을 통일된 날짜 형식으로 정규화하는 함수
    private static func normalizeDate(_ text: String) -> String {
        var date = text
        
        // 양쪽 공백 제거
        date = date.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // OCR 흔한 변형문자들을 . 으로 통일
        date = date.replacingOccurrences(of: "·", with: ".")
        date = date.replacingOccurrences(of: "•", with: ".")
        date = date.replacingOccurrences(of: "-", with: ".")
        date = date.replacingOccurrences(of: "/", with: ".")
        date = date.replacingOccurrences(of: "－", with: ".")
        date = date.replacingOccurrences(of: "~", with: ".")
        date = date.replacingOccurrences(of: "→", with: ".")
        
        // 중복 점 제거 (예: "2025..12..05" → "2025.12.05")
        while date.contains("..") {
            date = date.replacingOccurrences(of: "..", with: ".")
        }
        
        // 공백 제거 (예: "2025. 12 . 05" → "2025.12.05")
        date = date.replacingOccurrences(of: " ", with: "")
                
        // 다시 공백/점 정리
        date = date.trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        
        return date
    }
}
