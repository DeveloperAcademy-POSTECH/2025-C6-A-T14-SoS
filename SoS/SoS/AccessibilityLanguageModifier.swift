import SwiftUI

struct AccessibilityLanguageModifier: ViewModifier {
    let languageCode: String

    func body(content: Content) -> some View {
        content
            .background(AccessibilityLanguageView(languageCode: languageCode))
    }

    private struct AccessibilityLanguageView: UIViewRepresentable {
        let languageCode: String

        func makeUIView(context: Context) -> UIView {
            let view = UIView()
            view.isAccessibilityElement = true
            view.accessibilityLanguage = languageCode
            return view
        }

        func updateUIView(_ uiView: UIView, context: Context) {}
    }
}

extension View {
    func accessibilityLanguageCompat(_ code: String) -> some View {
        modifier(AccessibilityLanguageModifier(languageCode: code))
    }
}
