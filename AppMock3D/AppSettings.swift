import SwiftUI

extension Notification.Name {
    static let settingsDidUpdate = Notification.Name("settingsDidUpdate")
}

struct AppSettings: Codable, Equatable {
    // アスペクト比設定
    var aspectRatioPreset: AspectRatioPreset = .sixteenToNine
    var customAspectRatio: Double = 1.777
    
    // 寸法設定
    var width: Int = 1080
    var height: Int = 1920
    var maintainAspectRatio: Bool = true
    
    // 背景設定
    var backgroundColor: BackgroundColorSetting = .transparent
    var solidColorValue: String = "#303135"
    var gradientType: GradientType = .linear
    var gradientStartColor: String = "#FFFFFF"
    var gradientEndColor: String = "#000000"
    var environmentLightingIntensity: Double = 1.0
    
    // デバイスモデル選択
    var currentDeviceModel: DeviceModel = .iPhone15
    
    enum AspectRatioPreset: String, CaseIterable, Codable {
        case sixteenToNine = "16:9"
        case fourToThree = "4:3"
        case oneToOne = "1:1"
        case threeToFour = "3:4"
        case nineToSixteen = "9:16"
    }
    
    enum BackgroundColorSetting: String, CaseIterable, Codable {
        case solidColor = "Solid Color"
        case transparent = "Transparent"
        case gradient = "Gradient"
    }
    
    enum GradientType: String, CaseIterable, Codable {
        case linear = "Linear"
        case radial = "Radial"
    }
    
    enum DeviceModel: String, CaseIterable, Codable {
        case iPhone12 = "iPhone 12"
        case iPhone13 = "iPhone 13"
        case iPhone14 = "iPhone 14"
        case iPhone15 = "iPhone 15"
    }
}

extension AppSettings {
    static let defaults = AppSettings()
    
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: "AppSettings")
            // Notify that settings have been updated
            NotificationCenter.default.post(name: .settingsDidUpdate, object: nil)
        }
    }
    
    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: "AppSettings"),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings.defaults
        }
        return settings
    }
    
    // Validation functions
    static func isValidCustomAspectRatio(_ ratio: Double) -> Bool {
        return ratio >= 0.1 && ratio <= 10.0
    }
    
    static func isValidWidth(_ width: Int) -> Bool {
        return width >= 100 && width <= 4096
    }
    
    static func isValidHeight(_ height: Int) -> Bool {
        return height >= 100 && height <= 4096
    }
    
    static func isValidLightingIntensity(_ intensity: Double) -> Bool {
        return intensity >= 0.0 && intensity <= 2.0
    }
}
