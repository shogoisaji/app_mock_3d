import SwiftUI

struct AppBarView: View {
    var title: String
    var onSave: () -> Void
    var onSettings: () -> Void
    var onImageSelect: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // Right-aligned AppBar with minimum necessary width
        HStack {
            Spacer(minLength: 0)

            ZStack {
                // Background: Ultra thin blur + top gradient (applied only to the right-aligned block)
                BlurView(style: .systemUltraThinMaterial)
                    .overlay(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ).opacity(0.35)
                    )
                    .overlay(
                        // Inner stroke
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(borderColor, lineWidth: 0.6)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .opacity(0.6)
                    )

                HStack(spacing: 12) {
                    // Settings
                    PillIconButton(symbol: "gearshape", action: onSettings, accessibilityId: "gear")
                    
                    // Select Photo
                    PillIconButton(symbol: "photo", action: onImageSelect, accessibilityId: "imageSelect")
                    
                    // Save
                    PillIconButton(symbol: "square.and.arrow.down", action: onSave, accessibilityId: "save")
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 60)
            .fixedSize(horizontal: true, vertical: false) // Minimum necessary width
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: shadowColor, radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal, 12) // Padding from screen edge
        .padding(.top, 6)
        .accessibilityIdentifier("AppBar")
    }

    private var gradientColors: [Color] {
        let accent = Color.accentColor
        return [
            accent.opacity(colorScheme == .dark ? 0.18 : 0.22),
            Color.clear
        ]
    }

    private var borderColor: Color {
        colorScheme == .dark ? .white.opacity(0.12) : .black.opacity(0.06)
    }

    private var capsuleFill: Color {
        colorScheme == .dark ? .white.opacity(0.06) : .black.opacity(0.04)
    }

    private var capsuleStroke: Color {
        colorScheme == .dark ? .white.opacity(0.14) : .black.opacity(0.08)
    }

    private var shadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.5) : .black.opacity(0.12)
    }
}

// Modern rounded icon button
private struct PillIconButton: View {
    var symbol: String
    var action: () -> Void
    var accessibilityId: String

    @Environment(\.colorScheme) private var colorScheme
    @State private var pressed = false

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            action()
        }) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .frame(width: 36, height: 36)
                .foregroundStyle(.primary)
                .background(background)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(stroke, lineWidth: 0.6)
                )
                .scaleEffect(pressed ? 0.94 : 1)
                .animation(.spring(response: 0.28, dampingFraction: 0.9), value: pressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0).onChanged { _ in
                if !pressed { pressed = true }
            }.onEnded { _ in
                pressed = false
            }
        )
        .accessibilityIdentifier(accessibilityId)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
    }

    private var stroke: Color {
        colorScheme == .dark ? .white.opacity(0.12) : .black.opacity(0.08)
    }
}

// SwiftUI wrapper for UIKit blur
private struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct AppBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AppBarView(title: "タイトル", onSave: {}, onSettings: {}, onImageSelect: {})
            Spacer()
        }
        .padding(.top, 20)
        .background(
            LinearGradient(colors: [.blue.opacity(0.15), .purple.opacity(0.15)], startPoint: .top, endPoint: .bottom)
        )
        .preferredColorScheme(.light)

        VStack {
            AppBarView(title: "タイトル", onSave: {}, onSettings: {}, onImageSelect: {})
            Spacer()
        }
        .padding(.top, 20)
        .background(
            LinearGradient(colors: [.black, .indigo.opacity(0.35)], startPoint: .top, endPoint: .bottom)
        )
        .preferredColorScheme(.dark)
    }
}
