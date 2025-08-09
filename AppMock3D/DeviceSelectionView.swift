import SwiftUI

struct DeviceSelectionView: View {
    @Binding var settings: AppSettings
    @Binding var isPresented: Bool
    
    var body: some View {
        GlassContainer(cornerRadius: 20, intensity: .medium) {
            VStack(spacing: 16) {
// Device model selection (horizontal scroll with image + name)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Device")
                        .font(.headline)

                    ZStack {
                        GlassEffectView(
                            cornerRadius: 14,
                            borderLineWidth: 0.6,
                            shadowRadius: 6,
                            shadowOffset: CGSize(width: 0, height: 3),
                            intensity: .subtle
                        )
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 16) {
                                ForEach(AppSettings.DeviceModel.allCases, id: \.rawValue) { model in
                                    VStack(spacing: 8) {
                                        // image file name only for supported devices
                                        let imageName: String = {
                                            switch model {
                                            case .iPhone16: return "iphone16"
                                            case .iPhoneSE: return "iphoneSE"
                                            default: return ""
                                            }
                                        }()
                                        Image(uiImage: UIImage(named: imageName) ?? UIImage(named: "iphone16") ?? UIImage())
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 96, height: 96)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(settings.currentDeviceModel == model ? Color.accentColor : Color.white.opacity(0.3), lineWidth: settings.currentDeviceModel == model ? 3 : 1)
                                            )
                                            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)

                                        Text(model.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(8)
                                    .onTapGesture {
                                        // 即時適用してシートを閉じる
                                        settings.currentDeviceModel = model
                                        settings.save()
                                        isPresented = false
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                        }
                        .frame(height: 150)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 16)
    }
}

struct DeviceSelectionView_Previews: PreviewProvider {
    @State static var settings = AppSettings()
    @State static var isPresented = true
    
    static var previews: some View {
        DeviceSelectionView(settings: $settings, isPresented: $isPresented)
    }
}
