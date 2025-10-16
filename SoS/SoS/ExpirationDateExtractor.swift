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
            #"\d{2}\s*\.\s*\d{2}"#, // 10.15 (월/일)
            
            // 하이픈(-) 구분자: 2025-10-15, 25-10-15
            #"\d{4}\s*-\s*\d{2}\s*-\s*\d{2}"#, // 4자리 연도
            #"\d{2}\s*-\s*\d{2}\s*-\s*\d{2}"#, // 2자리 연도
            #"\d{2}\s*-\s*\d{2}"#, // 10-15 (월/일)
            
            // 슬래시(/) 구분자: 2025/10/15, 25/10/15
            #"\d{4}\s*/\s*\d{2}\s*/\s*\d{2}"#, // 4자리 연도
            #"\d{2}\s*/\s*\d{2}\s*/\s*\d{2}"#, // 2자리 연도
            #"\d{2}\s*/\s*\d{2}"#, // 10/15 (월/일)
            
            // OCR 변형 구분자(·, •, －, ~): 2025·10·15, 25•10•15, 2025－10－15, 25~10~15
            #"\d{4}\s*[·•－~]\s*\d{2}\s*[·•－~]\s*\d{2}"#, // 4자리 연도
            #"\d{2}\s*[·•－~]\s*\d{2}\s*[·•－~]\s*\d{2}"#, // 2자리 연도
            #"\d{2}\s*[·•－~]\s*\d{2}"#, // 10~15 (월/일)
            
            // 한글 포맷: 2025년 10월 15일, 25년 10월 15일
            #"\d{4}\s*년\s*\d{2}\s*월\s*\d{2}\s*일"#, // 4자리 연도
            #"\d{2}\s*년\s*\d{2}\s*월\s*\d{2}\s*일"#, // 2자리 연도
            #"\d{2}\s*월\s*\d{2}\s*일"#, // 10월 15일 (월/일)
            
            // 혼합형 구분자: 2025.10-15, 2025-10.15, 25.10-15 등
            #"\d{4}\s*[./·-]\s*\d{2}\s*[./·-]\s*\d{2}"#, // 4자리 연도
            #"\d{2}\s*[./·-]\s*\d{2}\s*[./·-]\s*\d{2}"#, // 2자리 연도
            #"\d{2}\s*[./·-]\s*\d{2}"#, // 10.15, 10-15 등 (월/일)
        ]
        
        for pattern in patterns {
            results.append(contentsOf: extractMatches(from: text, pattern: pattern))
        }
        
        let normalized = results.map { normalizeDate($0) }
        
        return filterDates(normalized)
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
    
    // 우선순위 기반 정제 로직
    private static func filterDates(_ dates: [String]) -> [String] {
        var fullDates = Set<String>()   // YYYY.MM.DD만 저장
        
        let now = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        
        for date in dates {
            let parts = date.split(separator: ".").map { String($0) }
            
            switch parts.count {
            case 3:
                // 년/월/일 형식 (YYYY.MM.DD 또는 YY.MM.DD)
                if var year = Int(parts[0]),
                   let month = Int(parts[1]),
                   let day = Int(parts[2]) {
                    
                    // 말도 안되는 날짜 (춘식이 사건) 제거
                    if year < currentYear - 5 || month > 12 || day > 31 {
                        continue
                    }
                    
                    // 2자리 연도 → 2000년대 보정
                    if year < 100 {
                        year += 2000
                    }
                    
                    let formatted = String(format: "%04d.%02d.%02d", year, month, day)
                    fullDates.insert(formatted)
                }
                
            case 2:
                // 월/일 형식 (MM.DD)
                if let month = Int(parts[0]), let day = Int(parts[1]),
                   month >= 1, month <= 12, day >= 1, day <= 31 {
                    
                    var year = currentYear
                    // 인식된 '월'이 현재 '월'보다 작으면 보정
                    if month < currentMonth {
                        year += 1
                    }
                    
                    let formatted = String(format: "%04d.%02d.%02d", year, month, day)
                    fullDates.insert(formatted)
                }
                
            default:
                continue
            }
        }
        
        // fullDates를 Date 타입으로 변환하여 최신 날짜 선택
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        
        let sorted = fullDates.compactMap { dateFormatter.date(from: $0) }.sorted()
        guard let latest = sorted.last else { return [] }
        
        let latestString = dateFormatter.string(from: latest)
        return [latestString]
    }
    
}
