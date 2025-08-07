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
                    // Aspect Ratio Settings with Glass Effect
                    GlassContainer(cornerRadius: 16, intensity: .subtle) {
                        VStack {
                            HStack {
                                Text("Aspect Ratio")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                                Text(getAspectRatioText())
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.secondary)
                                
                                // Glass preview rectangle
                                ZStack {
                                    GlassEffectView(
                                        cornerRadius: 3,
                                        borderLineWidth: 0.5,
                                        shadowRadius: 2,
                                        shadowOffset: CGSize(width: 0, height: 1),
                                        intensity: .medium
                                    )
                                }
                                .frame(width: getPreviewWidth(), height: getPreviewHeight())
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .rotationEffect(.degrees(showingAspectRatioSettings ? 90 : 0))
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingAspectRatioSettings)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
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
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        }
                        .padding()
                    }
                    
                    // Background Settings with Glass Effect
                    GlassContainer(cornerRadius: 16, intensity: .subtle) {
                        VStack {
                            HStack {
                                Text("Background")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                                if appState.settings.backgroundColor == .solidColor {
                                    ZStack {
                                        GlassEffectView(
                                            cornerRadius: 4,
                                            borderLineWidth: 0.5,
                                            shadowRadius: 2,
                                            shadowOffset: CGSize(width: 0, height: 1),
                                            intensity: .medium
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color(hex: appState.settings.solidColorValue) ?? .white)
                                                .opacity(0.8)
                                        )
                                    }
                                    .frame(width: 24, height: 24)
                                } else {
                                    Text(appState.settings.gradientType.rawValue)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.secondary)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .rotationEffect(.degrees(showingBackgroundSettings ? 90 : 0))
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingBackgroundSettings)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
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
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        }
                        .padding()
                    }
                    
                    // Device Selection Settings with Glass Effect
                    GlassLabelButton(
                        text: "Device Model",
                        symbol: "chevron.right",
                        action: {
                            showingDeviceSelection = true
                        },
                        accessibilityId: "deviceSelection",
                        height: 50,
                        cornerRadius: 16,
                        intensity: .subtle
                    )
                    .overlay(
                        HStack {
                            Spacer()
                            Text(appState.settings.currentDeviceModel.rawValue)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.secondary)
                                .padding(.trailing, 40) // Space for chevron
                        }
                        .padding(.horizontal, 16)
                    )
                }
                .padding()
            }
        }
        .background(Color(hex: "#B3B3B3"))
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
