import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
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
            VStack {
                HStack {
                    Text("背景")
                    Spacer()
                    if appState.settings.backgroundColor == .solidColor {
                        Rectangle()
                            .fill(Color(hex: appState.settings.solidColorValue) ?? .white)
                            .frame(width: 24, height: 24)
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    } else {
                        Text(appState.settings.gradientType.rawValue)
                    }
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(showingBackgroundSettings ? 90 : 0))
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        showingBackgroundSettings.toggle()
                    }
                }

                if showingBackgroundSettings {
                    VStack(alignment: .leading, spacing: 15) {
                        Picker("背景タイプ", selection: $appState.settings.backgroundColor) {
                            ForEach(AppSettings.BackgroundColorSetting.allCases, id: \.self) { type in
                                Text(type.rawValue)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        if appState.settings.backgroundColor == .solidColor {
                            ColorPicker("背景色", selection: Binding(get: {
                                Color(hex: appState.settings.solidColorValue) ?? Color.white
                            }, set: { color in
                                appState.settings.solidColorValue = color.toHex()
                            }))
                        }

                        if appState.settings.backgroundColor == .gradient {
                            Picker("グラデーション", selection: $appState.settings.gradientType) {
                                ForEach(AppSettings.GradientType.allCases, id: \.self) { type in
                                    Text(type.rawValue)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())

                            ColorPicker("開始色", selection: Binding(get: {
                                Color(hex: appState.settings.gradientStartColor) ?? .white
                            }, set: { color in
                                appState.settings.gradientStartColor = color.toHex()
                            }))

                            ColorPicker("終了色", selection: Binding(get: {
                                Color(hex: appState.settings.gradientEndColor) ?? .black
                            }, set: { color in
                                appState.settings.gradientEndColor = color.toHex()
                            }))
                        }
                    }
                    .padding(.top, 10)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // 端末選択設定
            Button(action: {
                showingDeviceSelection = true
            }) {
                HStack {
                    Text("端末モデル")
                    Spacer()
                    Text(appState.settings.currentDeviceModel.rawValue)
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
            content: AspectRatioSettingsView(settings: $appState.settings, isPresented: $showingAspectRatioSettings),
            height: 350
        )
        
        
        
        // Device Selection Bottom Sheet
        BottomSheetManager(
            isOpen: $showingDeviceSelection,
            content: DeviceSelectionView(settings: $appState.settings, isPresented: $showingDeviceSelection),
            height: 300
        )
        .onChange(of: appState.settings) { _, newSettings in
            newSettings.save()
        }
    }
    
    private func getAspectRatioText() -> String {
        switch appState.settings.aspectRatioPreset {
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
