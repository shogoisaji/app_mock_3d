import SwiftUI

struct AspectRatioSettingsView: View {
    @Binding var settings: AppSettings
    @Binding var isPresented: Bool
    
    var body: some View {
        GlassContainer(cornerRadius: 20, intensity: .medium) {
            VStack(spacing: 16) {
                // Remove the title section
                
                // Preset selection
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("aspect_ratio", comment: "Aspect Ratio"))
                        .font(.headline)
                    
                    Picker(NSLocalizedString("aspect_ratio_preset", comment: "Aspect Ratio Preset"), selection: $settings.aspectRatioPreset) {
                        ForEach(AppSettings.AspectRatioPreset.allCases, id: \.rawValue) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: settings.aspectRatioPreset) { _ in
                        settings.save()
                    }
                }
                // 即時適用のため、カスタム比率やボタンは不要
            }
            .padding(16)
        }
        .padding(.horizontal, 16)
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
