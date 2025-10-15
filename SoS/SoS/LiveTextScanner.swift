//
//  LiveTextScanner.swift
//  SoS
//
//  Created by 서세린 on 10/14/25.
//

import SwiftUI
import VisionKit

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
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }
    
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
