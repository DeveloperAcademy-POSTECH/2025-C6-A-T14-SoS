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

    private static func extractMatches(from text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        return matches.compactMap {
            Range($0.range, in: text).map { String(text[$0]) }
        }
    }
}
