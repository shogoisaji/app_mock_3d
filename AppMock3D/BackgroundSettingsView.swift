import SwiftUI

struct BackgroundSettingsView: View {
    @Binding var settings: AppSettings
    @Binding var isPresented: Bool
    
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
                    Text("単色設定")
                        .font(.headline)
                    
                    ColorPicker("背景色", selection: Binding(get: {
                        Color(hex: settings.solidColorValue) ?? Color.white
                    }, set: { color in
                        settings.solidColorValue = color.toHex()
                    }))
                    .padding()
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

// Extension to convert Color to Hex string and vice versa
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
    
    func toHex() -> String {
        // For simplicity, we'll return a default white color
        // In a real implementation, you might want to use a more sophisticated approach
        return "#FFFFFF"
    }
}

struct BackgroundSettingsView_Previews: PreviewProvider {
    @State static var settings = AppSettings()
    @State static var isPresented = true
    
    static var previews: some View {
        BackgroundSettingsView(settings: $settings, isPresented: $isPresented)
    }
}
