import SwiftUI

class AppState: ObservableObject {
    @Published var currentMode: InteractionMode = .move
    @Published var isSettingsPresented: Bool = false
    @Published var settings: AppSettings = AppSettings.load()
    
    // 設定値
    @Published var aspectRatio: Double = 1.777  // 16:9
    @Published var backgroundColor: Color = .white
    @Published var currentDevice: iPhoneModel = .iPhone15
    
    // 画像関連の状態管理
    @Published var isImageProcessing: Bool = false
    @Published var imageError: String?
    @Published var hasImageApplied: Bool = false
    
    func setMode(_ mode: InteractionMode) {
        currentMode = mode
    }
    
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
