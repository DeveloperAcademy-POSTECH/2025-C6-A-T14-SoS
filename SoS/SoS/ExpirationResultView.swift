//
//  ExpirationResultView.swift
//  SoS
//
//  Created by 서세린 on 10/14/25.
//

import SwiftUI

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
