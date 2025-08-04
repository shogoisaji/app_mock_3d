import SwiftUI

struct AspectRatioSettingsView: View {
    @Binding var settings: AppSettings
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("アスペクト比設定")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)
            
            // Preset selection
            VStack(alignment: .leading, spacing: 10) {
                Text("プリセット")
                    .font(.headline)
                
                Picker("アスペクト比プリセット", selection: $settings.aspectRatioPreset) {
                    ForEach(AppSettings.AspectRatioPreset.allCases, id: \\.rawValue) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 100)
            }
            
            // Custom aspect ratio
            VStack(alignment: .leading, spacing: 10) {
                Text("カスタムアスペクト比")
                    .font(.headline)
                
                HStack {
                    Text(String(format: "%.3f", settings.customAspectRatio))
                        .frame(width: 50)
                    
                    Slider(
                        value: $settings.customAspectRatio,
                        in: 0.1...10.0,
                        step: 0.001
                    )
                    .onChange(of: settings.customAspectRatio) { _ in
                        // When custom aspect ratio is changed, we might want to update other settings
                    }
                }
            }
            
            // Current aspect ratio display
            VStack(alignment: .leading, spacing: 10) {
                Text("現在のアスペクト比")
                    .font(.headline)
                
                Text(getCurrentAspectRatio())
                    .font(.title3)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
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
    
    private func getCurrentAspectRatio() -> String {
        return String(format: "%.3f", settings.customAspectRatio)
    }
}

struct AspectRatioSettingsView_Previews: PreviewProvider {
    @State static var settings = AppSettings()
    @State static var isPresented = true
    
    static var previews: some View {
        AspectRatioSettingsView(settings: $settings, isPresented: $isPresented)
    }
}
