import SwiftUI

class AppState: ObservableObject {
    
    @Published var isSettingsPresented: Bool = false
    @Published var settings: AppSettings = AppSettings.load()
    
    // 設定値
    @Published var backgroundColor: Color = .white
    @Published var currentDevice: iPhoneModel = .iPhone15
    
    // アスペクト比を設定から計算
    var aspectRatio: Double {
        switch settings.aspectRatioPreset {
        case .sixteenToNine:
            return 16.0 / 9.0
        case .fourToThree:
            return 4.0 / 3.0
        case .oneToOne:
            return 1.0
        case .threeToFour:
            return 3.0 / 4.0
        case .nineToSixteen:
            return 9.0 / 16.0
        }
    }
    
    // 画像関連の状態管理
    @Published var isImageProcessing: Bool = false
    @Published var imageError: String?
    @Published var hasImageApplied: Bool = false
    
    
    
    func toggleSettings() {
        isSettingsPresented.toggle()
    }
    
    func setImageProcessing(_ processing: Bool) {
        isImageProcessing = processing
        if processing {
            imageError = nil
        }
    }
    
    func setImageError(_ error: String?) {
        imageError = error
        isImageProcessing = false
    }
    
    func setImageApplied(_ applied: Bool) {
        hasImageApplied = applied
        if applied {
            imageError = nil
        }
    }
    
    func clearImageState() {
        hasImageApplied = false
        imageError = nil
        isImageProcessing = false
    }
}
