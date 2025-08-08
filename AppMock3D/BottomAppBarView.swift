import SwiftUI

struct BottomAppBarView: View {
    var onGridToggle: () -> Void
    var onLightingAdjust: () -> Void
    var onResetTransform: () -> Void
    // 背景色の双方向バインド（ColorPickerを直接表示）
    @Binding var backgroundColorBinding: Color
    var onAspectTap: () -> Void
    var onDeviceTap: () -> Void
    // 表示用現在値
    var lightingNumber: Int = 1
    var backgroundDisplayColor: Color
    var aspectRatio: Double
    var deviceLabel: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Spacer(minLength: 0)
            GlassContainer(cornerRadius: 20, intensity: .medium) {
                HStack(spacing: 12) {
                    // 背景色 ColorPicker（直接表示）
                    ColorPicker("", selection: $backgroundColorBinding, supportsOpacity: true)
                        .labelsHidden()
                        .frame(width: 36, height: 36)
                        .background(
                            ZStack {
                                GlassEffectView(
                                    cornerRadius: 12,
                                    borderLineWidth: 0.6,
                                    shadowRadius: 6,
                                    shadowOffset: CGSize(width: 0, height: 3),
                                    intensity: .medium
                                )
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(backgroundDisplayColor)
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.15), lineWidth: 1)
                                    )
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityIdentifier("backgroundButton")

                    // アスペクト比ボタン（現在の比率で矩形を表示）
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        onAspectTap()
                    }) {
                        ZStack {
                            GlassEffectView(
                                cornerRadius: 12,
                                borderLineWidth: 0.6,
                                shadowRadius: 6,
                                shadowOffset: CGSize(width: 0, height: 3),
                                intensity: .medium
                            )
                            // 24x24 の枠内にアスペクト比を保ってフィット
                            let box: CGFloat = 24
                            let r = max(0.1, min(10.0, CGFloat(aspectRatio)))
                            let rectWidth: CGFloat = r >= 1 ? box : box * r
                            let rectHeight: CGFloat = r >= 1 ? box / r : box
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.primary.opacity(0.6), lineWidth: 1.2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.primary.opacity(0.08))
                                )
                                .frame(width: rectWidth, height: rectHeight)
                                .frame(width: box, height: box)
                        }
                        .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("aspectButton")

                    // デバイスボタン（例: 15）
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        onDeviceTap()
                    }) {
                        ZStack {
                            GlassEffectView(
                                cornerRadius: 12,
                                borderLineWidth: 0.6,
                                shadowRadius: 6,
                                shadowOffset: CGSize(width: 0, height: 3),
                                intensity: .medium
                            )
                            Text(deviceLabel)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                        .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("deviceButton")

                    // Toggle grid helper lines
                    GlassButton(
                        symbol: "grid",
                        action: onGridToggle,
                        accessibilityId: "gridToggle",
                        size: 36,
                        cornerRadius: 12
                    )
                    
                    // Adjust lighting (with number badge)
                    ZStack(alignment: .bottomTrailing) {
                        GlassButton(
                            symbol: "lightbulb",
                            action: onLightingAdjust,
                            accessibilityId: "lightingAdjust",
                            size: 36,
                            cornerRadius: 12
                        )
                        // Badge with glass effect
                        ZStack {
                            GlassEffectView(
                                cornerRadius: 8,
                                borderLineWidth: 0.5,
                                shadowRadius: 4,
                                shadowOffset: CGSize(width: 0, height: 2),
                                intensity: .strong
                            )
                            
                            Text("\(max(1, min(10, lightingNumber)))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                        .frame(width: 18, height: 16)
                        .offset(x: 1, y: 1)
                        .accessibilityHidden(true)
                    }
                    
                    // Reset placement
                    GlassButton(
                        symbol: "arrow.counterclockwise",
                        action: onResetTransform,
                        accessibilityId: "resetTransform",
                        size: 36,
                        cornerRadius: 12
                    )
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 60)
            .fixedSize(horizontal: true, vertical: false)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
        .accessibilityIdentifier("BottomAppBar")
    }
    
}

struct BottomAppBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            BottomAppBarView(
                onGridToggle: {},
                onLightingAdjust: {},
                onResetTransform: {},
                backgroundColorBinding: .constant(.blue),
                onAspectTap: {},
                onDeviceTap: {},
                lightingNumber: 3,
                backgroundDisplayColor: .blue,
                aspectRatio: 16.0/9.0,
                deviceLabel: "15"
            )
        }
        .padding(.bottom, 20)
        .background(
            LinearGradient(colors: [.blue.opacity(0.15), .purple.opacity(0.15)], startPoint: .top, endPoint: .bottom)
        )
        .preferredColorScheme(.light)
        
        VStack {
            Spacer()
            BottomAppBarView(
                onGridToggle: {},
                onLightingAdjust: {},
                onResetTransform: {},
                backgroundColorBinding: .constant(.green),
                onAspectTap: {},
                onDeviceTap: {},
                lightingNumber: 7,
                backgroundDisplayColor: .green,
                aspectRatio: 9.0/16.0,
                deviceLabel: "16"
            )
        }
        .padding(.bottom, 20)
        .background(
            LinearGradient(colors: [.black, .indigo.opacity(0.35)], startPoint: .top, endPoint: .bottom)
        )
        .preferredColorScheme(.dark)
    }
}