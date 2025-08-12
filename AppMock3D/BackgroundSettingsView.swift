import SwiftUI
import UIKit

struct BackgroundSettingsView: View {
    @Binding var settings: AppSettings
    @Binding var isPresented: Bool
    @State private var isColorPickerVisible = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(NSLocalizedString("background_settings", comment: "Background Settings"))
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)
            
            // Background type selection
            VStack(alignment: .leading, spacing: 10) {
                Text(NSLocalizedString("background_type", comment: "Background Type"))
                    .font(.headline)
                
                Picker(NSLocalizedString("background_type", comment: "Background Type"), selection: $settings.backgroundColor) {
                    ForEach(AppSettings.BackgroundColorSetting.allCases, id: \.rawValue) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Solid color settings
            if settings.backgroundColor == .solidColor {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(NSLocalizedString("solid_color_settings", comment: "Solid Color Settings"))
                            .font(.headline)
                        Spacer()
                        Rectangle()
                            .fill(Color(hex: settings.solidColorValue) ?? Color.white)
                            .frame(width: 30, height: 30)
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }
                    .onTapGesture {
                        withAnimation {
                            isColorPickerVisible.toggle()
                        }
                    }
                    
                    if isColorPickerVisible {
                        VStack(spacing: 15) {
                            // プリセットカラーグリッド
                            VStack(alignment: .leading, spacing: 10) {
                                Text(NSLocalizedString("background_color", comment: "Background Color"))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                let presetColors: [String] = [
                                    "#FFFFFF", "#F0F0F0", "#E0E0E0", "#D0D0D0",
                                    "#FF0000", "#FF8000", "#FFFF00", "#80FF00",
                                    "#00FF00", "#00FF80", "#00FFFF", "#0080FF",
                                    "#0000FF", "#8000FF", "#FF00FF", "#FF0080",
                                    "#800000", "#808000", "#008000", "#008080",
                                    "#000080", "#800080", "#808080", "#000000"
                                ]
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                                    ForEach(presetColors, id: \.self) { colorHex in
                                        Rectangle()
                                            .fill(Color(hex: colorHex) ?? Color.white)
                                            .frame(width: 30, height: 30)
                                            .cornerRadius(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(
                                                        settings.solidColorValue == colorHex ? Color.blue : Color.gray.opacity(0.3),
                                                        lineWidth: settings.solidColorValue == colorHex ? 3 : 1
                                                    )
                                            )
                                            .onTapGesture {
                                                settings.solidColorValue = colorHex
                                            }
                                    }
                                }
                            }
                            
                            // 透明度0%ボタン
                            HStack {
                                Text(NSLocalizedString("transparency", comment: "Transparency"))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(NSLocalizedString("make_transparent", comment: "Make Transparent")) {
                                    if let currentColor = Color(hex: settings.solidColorValue) {
                                        let transparentColor = currentColor.opacity(0)
                                        settings.solidColorValue = transparentColor.toHex(includeAlpha: true)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                                .font(.system(size: 14, weight: .medium))
                            }
                        }
                        .padding()
                    }
                }
            }
            
            // Gradient settings
            if settings.backgroundColor == .gradient {
                VStack(alignment: .leading, spacing: 10) {
                    Text(NSLocalizedString("gradient_type", comment: "Gradient Type"))
                        .font(.headline)
                    
                    Picker(NSLocalizedString("gradient", comment: "Gradient"), selection: $settings.gradientType) {
                        ForEach(AppSettings.GradientType.allCases, id: \.rawValue) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            
            // Environment lighting
            VStack(alignment: .leading, spacing: 10) {
                Text(NSLocalizedString("environment_lighting", comment: "Environment Lighting"))
                    .font(.headline)
                
                HStack {
                    Text(String(format: NSLocalizedString("intensity_format", comment: "Intensity: %.1f"), settings.environmentLightingIntensity))
                    Spacer()
                }
                
                Slider(
                    value: $settings.environmentLightingIntensity,
                    in: 0.0...2.0,
                    step: 0.1
                )
            }
            
            Spacer()
            
            // Action buttons
            HStack {
                Button(NSLocalizedString("cancel", comment: "Cancel")) {
                    isPresented = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray5))
                .cornerRadius(8)
                
                Button(NSLocalizedString("apply", comment: "Apply")) {
                    settings.save()
                    isPresented = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
    }
}



struct BackgroundSettingsView_Previews: PreviewProvider {
    @State static var settings = AppSettings()
    @State static var isPresented = true
    
    static var previews: some View {
        BackgroundSettingsView(settings: $settings, isPresented: $isPresented)
    }
}
