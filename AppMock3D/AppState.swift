import SwiftUI

class AppState: ObservableObject {
    @Published var currentMode: InteractionMode = .move
    @Published var isSettingsPresented: Bool = false
    
    // 設定値
    @Published var aspectRatio: Double = 1.777  // 16:9
    @Published var backgroundColor: Color = .white
    @Published var currentDevice: iPhoneModel = .iPhone15
    
    func setMode(_ mode: InteractionMode) {
        currentMode = mode
    }
    
    func toggleSettings() {
        isSettingsPresented.toggle()
    }
}
