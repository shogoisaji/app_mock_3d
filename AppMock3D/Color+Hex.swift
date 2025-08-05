import SwiftUI
import UIKit

// Extension to convert Color to Hex string and vice versa
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
    
    func toHex() -> String {
        let uicolor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard uicolor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            // Fallback for non-RGB colors
            return "#000000"
        }

        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}
// アプリのテーマ定義
struct AppTheme {
    let background: Color
    let primary: Color
    let secondary: Color
    
    static let dark = AppTheme(
        background: Color(hex: "#303135") ?? Color(red: 48/255, green: 49/255, blue: 53/255),
        primary: Color(hex: "#E99370") ?? Color(red: 233/255, green: 147/255, blue: 112/255),
        secondary: Color(hex: "#86B9D9") ?? Color(red: 233/255, green: 147/255, blue: 112/255)
    )
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .dark
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

extension View {
    func appTheme(_ theme: AppTheme) -> some View {
        environment(\.appTheme, theme)
    }
}
