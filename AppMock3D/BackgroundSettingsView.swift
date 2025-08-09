import SwiftUI
import UIKit

struct BackgroundSettingsView: View {
    @Binding var settings: AppSettings
    @Binding var isPresented: Bool
    @State private var isColorPickerVisible = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Background Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)
            
            // Background type selection
            VStack(alignment: .leading, spacing: 10) {
                Text("Background Type")
                    .font(.headline)
                
                Picker("Background Type", selection: $settings.backgroundColor) {
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
                        Text("Solid Color Settings")
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
                                Text("Background Color")
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
                                Text("Transparency")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Make Transparent") {
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
                    Text("Gradient Type")
                        .font(.headline)
                    
                    Picker("Gradient", selection: $settings.gradientType) {
                        ForEach(AppSettings.GradientType.allCases, id: \.rawValue) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            
            // Environment lighting
            VStack(alignment: .leading, spacing: 10) {
                Text("Environment Lighting")
                    .font(.headline)
                
                HStack {
                    Text("Intensity: \(String(format: "%.1f", settings.environmentLightingIntensity))")
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
                Button("Cancel") {
                    isPresented = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray5))
                .cornerRadius(8)
                
                Button("Apply") {
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
