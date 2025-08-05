import SwiftUI

struct BottomAppBarView: View {
    var onGridToggle: () -> Void
    var onLightingAdjust: () -> Void
    var onResetTransform: () -> Void
    // 追加: 現在のライティング番号(1~4)を表示するために受け取る
    var lightingNumber: Int = 1
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            ZStack {
                // 背景: 超薄ブラー
                BlurView(style: .systemUltraThinMaterial)
                    .overlay(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ).opacity(0.35)
                    )
                    .overlay(
                        // 内側ストローク
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(borderColor, lineWidth: 0.6)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .opacity(0.6)
                    )
                
                HStack(spacing: 12) {
                    // グリッドの補助線表示切り替え
                    PillIconButton(symbol: "grid", action: onGridToggle, accessibilityId: "gridToggle")
                    
                    // ライティング調整（番号バッジつき）
                    ZStack(alignment: .topTrailing) {
                        PillIconButton(symbol: "lightbulb", action: onLightingAdjust, accessibilityId: "lightingAdjust")
                        // バッジ（1〜10対応: 2桁でも視認性が保てるようサイズ調整）
                        Text("\(max(1, min(10, lightingNumber)))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 5)
                            .background(
                                Capsule().fill(Color.red.opacity(0.9))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.8), lineWidth: 0.6))
                            )
                            .offset(x: 10, y: -10)
                            .accessibilityHidden(true)
                    }
                    
                    // 配置リセット
                    PillIconButton(symbol: "arrow.counterclockwise", action: onResetTransform, accessibilityId: "resetTransform")
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 60)
            .fixedSize(horizontal: true, vertical: false) // 必要な幅のみ
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: shadowColor, radius: 12, x: 0, y: 6)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12) // 画面端との余白
        .padding(.bottom, 6)
        .accessibilityIdentifier("BottomAppBar")
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
    
    private var shadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.5) : .black.opacity(0.12)
    }
}

// モダンな丸角アイコンボタン
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

// UIKit ブラーの SwiftUI ラッパー
private struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct BottomAppBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            BottomAppBarView(onGridToggle: {}, onLightingAdjust: {}, onResetTransform: {})
        }
        .padding(.bottom, 20)
        .background(
            LinearGradient(colors: [.blue.opacity(0.15), .purple.opacity(0.15)], startPoint: .top, endPoint: .bottom)
        )
        .preferredColorScheme(.light)
        
        VStack {
            Spacer()
            BottomAppBarView(onGridToggle: {}, onLightingAdjust: {}, onResetTransform: {})
        }
        .padding(.bottom, 20)
        .background(
            LinearGradient(colors: [.black, .indigo.opacity(0.35)], startPoint: .top, endPoint: .bottom)
        )
        .preferredColorScheme(.dark)
    }
}