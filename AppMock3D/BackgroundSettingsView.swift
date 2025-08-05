import SwiftUI
import UIKit

struct BackgroundSettingsView: View {
    @Binding var settings: AppSettings
    @Binding var isPresented: Bool
    @State private var isColorPickerVisible = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("背景設定")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)
            
            // Background type selection
            VStack(alignment: .leading, spacing: 10) {
                Text("背景タイプ")
                    .font(.headline)
                
                Picker("背景タイプ", selection: $settings.backgroundColor) {
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
                        Text("単色設定")
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
                        ColorPicker("背景色", selection: Binding(get: {
                            Color(hex: settings.solidColorValue) ?? Color.white
                        }, set: { color in
                            settings.solidColorValue = color.toHex()
                        }))
                        .padding()
                    }
                }
            }
            
            // Gradient settings
            if settings.backgroundColor == .gradient {
                VStack(alignment: .leading, spacing: 10) {
                    Text("グラデーションタイプ")
                        .font(.headline)
                    
                    Picker("グラデーション", selection: $settings.gradientType) {
                        ForEach(AppSettings.GradientType.allCases, id: \.rawValue) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            
            // Environment lighting
            VStack(alignment: .leading, spacing: 10) {
                Text("環境ライティング")
                    .font(.headline)
                
                HStack {
                    Text("強度: \(String(format: "%.1f", settings.environmentLightingIntensity))")
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
                Button("キャンセル") {
                    isPresented = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray5))
                .cornerRadius(8)
                
                Button("適用") {
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
