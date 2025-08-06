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
                        ColorPicker("Background Color", selection: Binding(get: {
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
