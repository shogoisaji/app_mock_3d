import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var settings = AppSettings.load()
    @State private var showingAspectRatioSettings = false
    @State private var showingBackgroundSettings = false
    @State private var showingDeviceSelection = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("設定")
                .font(.title)
                .padding()
            
            // アスペクト比設定
            Button(action: {
                showingAspectRatioSettings = true
            }) {
                HStack {
                    Text("アスペクト比")
                    Spacer()
                    Text(getAspectRatioText())
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // 背景設定
            Button(action: {
                showingBackgroundSettings = true
            }) {
                HStack {
                    Text("背景")
                    Spacer()
                    Text(settings.backgroundColor.rawValue)
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // 端末選択設定
            Button(action: {
                showingDeviceSelection = true
            }) {
                HStack {
                    Text("端末モデル")
                    Spacer()
                    Text(settings.currentDeviceModel.rawValue)
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
        
        // Aspect Ratio Bottom Sheet
        BottomSheetManager(
            isOpen: $showingAspectRatioSettings,
            content: AspectRatioSettingsView(settings: $settings, isPresented: $showingAspectRatioSettings),
            height: 350
        )
        
        // Background Bottom Sheet
        BottomSheetManager(
            isOpen: $showingBackgroundSettings,
            content: BackgroundSettingsView(settings: $settings, isPresented: $showingBackgroundSettings),
            height: 400
        )
        
        // Device Selection Bottom Sheet
        BottomSheetManager(
            isOpen: $showingDeviceSelection,
            content: DeviceSelectionView(settings: $settings, isPresented: $showingDeviceSelection),
            height: 300
        )
    }
    
    private func getAspectRatioText() -> String {
        switch settings.aspectRatioPreset {
        case .sixteenToNine:
            return "16:9"
        case .fourToThree:
            return "4:3"
        case .oneToOne:
            return "1:1"
        case .threeToFour:
            return "3:4"
        case .nineToSixteen:
            return "9:16"
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(appState: AppState())
    }
}
