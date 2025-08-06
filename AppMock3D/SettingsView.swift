import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var showingAspectRatioSettings = false
    @State private var showingBackgroundSettings = false
    @State private var showingDeviceSelection = false
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Settings")
                .font(.title)
                .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Aspect Ratio Settings
                    VStack {
                        HStack {
                            Text("Aspect Ratio")
                            Spacer()
                            Text(getAspectRatioText())
                            Rectangle()
                                .fill(Color(.systemGray4))
                                .frame(width: getPreviewWidth(), height: getPreviewHeight())
                                .cornerRadius(2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                            Image(systemName: "chevron.right")
                                .rotationEffect(.degrees(showingAspectRatioSettings ? 90 : 0))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                showingAspectRatioSettings.toggle()
                            }
                        }
                        
                        if showingAspectRatioSettings {
                            VStack(alignment: .leading, spacing: 15) {
                                Picker("Aspect Ratio Preset", selection: $appState.settings.aspectRatioPreset) {
                                    ForEach(AppSettings.AspectRatioPreset.allCases, id: \.self) { preset in
                                        Text(preset.rawValue)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            .padding(.top, 10)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    // Background Settings
                    VStack {
                        HStack {
                            Text("Background")
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
                                Picker("Background Type", selection: $appState.settings.backgroundColor) {
                                    ForEach(AppSettings.BackgroundColorSetting.allCases, id: \.self) { type in
                                        Text(type.rawValue)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                
                                if appState.settings.backgroundColor == .solidColor {
                                    ColorPicker("Background Color", selection: Binding(get: {
                                        Color(hex: appState.settings.solidColorValue) ?? Color.white
                                    }, set: { color in
                                        appState.settings.solidColorValue = color.toHex()
                                    }))
                                }
                                
                                if appState.settings.backgroundColor == .gradient {
                                    Picker("Gradient", selection: $appState.settings.gradientType) {
                                        ForEach(AppSettings.GradientType.allCases, id: \.self) { type in
                                            Text(type.rawValue)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    
                                    ColorPicker("Start Color", selection: Binding(get: {
                                        Color(hex: appState.settings.gradientStartColor) ?? .white
                                    }, set: { color in
                                        appState.settings.gradientStartColor = color.toHex()
                                    }))
                                    
                                    ColorPicker("End Color", selection: Binding(get: {
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
                    
                    // Device Selection Settings
                    Button(action: {
                        showingDeviceSelection = true
                    }) {
                        HStack {
                            Text("Device Model")
                            Spacer()
                            Text(appState.settings.currentDeviceModel.rawValue)
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding()
                }
                .padding()
            }
        }
        .background(Color(hex: "#303135") ?? Color(red: 48/255, green: 49/255, blue: 53/255))
        .cornerRadius(24)
        .shadow(radius: 5)
        .overlay(
            // Device Selection Bottom Sheet
            BottomSheetManager(
                isOpen: $showingDeviceSelection,
                content: DeviceSelectionView(settings: $appState.settings, isPresented: $showingDeviceSelection)
            )
        )
        .onChange(of: appState.settings) { _, newSettings in
            newSettings.save()
        }
        .tint(Color(hex: "#E99370") ?? .orange)
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
    
    private func getAspectRatio() -> Double {
        switch appState.settings.aspectRatioPreset {
        case .sixteenToNine:
            return 16.0 / 9.0
        case .fourToThree:
            return 4.01 / 3.0
        case .oneToOne:
            return 1.0
        case .threeToFour:
            return 3.0 / 4.0
        case .nineToSixteen:
            return 9.0 / 16.0
        }
    }
    
    private func getPreviewWidth() -> CGFloat {
        let aspectRatio = getAspectRatio()
        let baseSize: CGFloat = 24
        
        if aspectRatio >= 1.0 {
            return baseSize
        } else {
            return baseSize * aspectRatio
        }
    }
    
    private func getPreviewHeight() -> CGFloat {
        let aspectRatio = getAspectRatio()
        let baseSize: CGFloat = 24
        
        if aspectRatio >= 1.0 {
            return baseSize / aspectRatio
        } else {
            return baseSize
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(appState: AppState())
    }
}
