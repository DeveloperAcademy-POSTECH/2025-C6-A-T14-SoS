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
            #"\d{4}\s*\.\s*\d{1,2}\s*\.\s*\d{1,2}"#, // 4자리 연도
            #"\d{2}\s*\.\s*\d{1,2}\s*\.\s*\d{1,2}"#, // 2자리 연도
            #"\d{4}\s*\.\s*\d{1,2}"#, // 2025.10 (년/월)
            #"\d{2}\s*\.\s*\d{1,2}"#, // 25.10 (년/월)
            #"\d{1,2}\s*\.\s*\d{1,2}"#, // 10.15 (월/일)

            // 하이픈(-) 구분자: 2025-10-15, 25-10-15
            #"\d{4}\s*-\s*\d{1,2}\s*-\s*\d{1,2}"#, // 4자리 연도
            #"\d{2}\s*-\s*\d{1,2}\s*-\s*\d{1,2}"#, // 2자리 연도
            #"\d{4}\s*-\s*\d{1,2}"#, // 2025-10 (년/월)
            #"\d{2}\s*-\s*\d{1,2}"#, // 25-10 (년/월)
            #"\d{1,2}\s*-\s*\d{1,2}"#, // 10-15 (월/일)

            // 슬래시(/) 구분자: 2025/10/15, 25/10/15
            #"\d{4}\s*/\s*\d{1,2}\s*/\s*\d{1,2}"#, // 4자리 연도
            #"\d{2}\s*/\s*\d{1,2}\s*/\s*\d{1,2}"#, // 2자리 연도
            #"\d{4}\s*/\s*\d{1,2}"#, // 2025/10 (년/월)
            #"\d{2}\s*/\s*\d{1,2}"#, // 25/10 (년/월)
            #"\d{1,2}\s*/\s*\d{1,2}"#, // 10/15 (월/일)

            // OCR 변형 구분자(·, •, －, ~): 2025·10·15, 25•10•15, 2025－10－15, 25~10~15
            #"\d{4}\s*[·•－~]\s*\d{1,2}\s*[·•－~]\s*\d{1,2}"#, // 4자리 연도
            #"\d{2}\s*[·•－~]\s*\d{1,2}\s*[·•－~]\s*\d{1,2}"#, // 2자리 연도
            #"\d{4}\s*[·•－~]\s*\d{1,2}"#, // 2025·10 (년/월)
            #"\d{2}\s*[·•－~]\s*\d{1,2}"#, // 25•10 (년/월)
            #"\d{1,2}\s*[·•－~]\s*\d{1,2}"#, // 10~15 (월/일)

            // 한글 포맷: 2025년 10월 15일, 25년 10월 15일
            #"\d{4}\s*년\s*\d{1,2}\s*월\s*\d{1,2}\s*일"#, // 4자리 연도
            #"\d{2}\s*년\s*\d{1,2}\s*월\s*\d{1,2}\s*일"#, // 2자리 연도
            #"\d{4}\s*년\s*\d{1,2}\s*월"#, // 2025년 10월 (년/월)
            #"\d{2}\s*년\s*\d{1,2}\s*월"#, // 25년 10월 (년/월)
            #"\d{1,2}\s*월\s*\d{1,2}\s*일"#, // 10월 15일 (월/일)

            // 혼합형 구분자: 2025.10-15, 2025-10.15, 25.10-15 등
            #"\d{4}\s*[./·-]\s*\d{1,2}\s*[./·-]\s*\d{1,2}"#, // 4자리 연도
            #"\d{2}\s*[./·-]\s*\d{1,2}\s*[./·-]\s*\d{1,2}"#, // 2자리 연도
            #"\d{4}\s*[./·-]\s*\d{1,2}"#, // 2025.10, 2025-10 등 (년/월)
            #"\d{2}\s*[./·-]\s*\d{1,2}"#, // 25.10, 25-10 등 (년/월)
            #"\d{1,2}\s*[./·-]\s*\d{1,2}"#, // 10.15, 10-15 등 (월/일)
        ]

        for pattern in patterns {
            results.append(contentsOf: extractMatches(from: text, pattern: pattern))
        }

        return Array(Set(results)).sorted()
    }

    private static func extractMatches(from text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        return matches.compactMap {
            Range($0.range, in: text).map { String(text[$0]) }
        }
    }
}
