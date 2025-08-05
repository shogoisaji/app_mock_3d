import SwiftUI

struct BottomNavView: View {
    @ObservedObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // 横スクロールできる等間隔アイコン行
        ZStack(alignment: .center) {
            // 背景
            BlurView(style: .systemUltraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: shadowColor, radius: 18, x: 0, y: 10)
                .padding(.horizontal, 12)
                .padding(.bottom, 6)

            // スクロール可能な水平リスト
            ScrollView(.horizontal, showsIndicators: false) {
                // 内側余白
                HStack(spacing: 12) {
                    // 均一なアイコンサイズの Pill 風ボタンを並べる
                    iconTab(.move, "arrow.up.left.and.arrow.down.right", "移動")
                    iconTab(.scale, "arrow.up.left.arrow.down.right", "拡大縮小")
                    iconTab(.rotate, "rotate.3d", "回転")
                    iconTab(.aspect, "rectangle.ratio", "アスペクト比")
                    iconTab(.background, "photo", "背景")
                    iconTab(.device, "iphone", "端末")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .padding(.horizontal, 12) // 背景の丸角と整合
        }
        .frame(height: 80)
        .accessibilityIdentifier("Bottom Navigation")
    }

    // 横スクロール前提のアイコン等幅タブ
    @ViewBuilder
    private func iconTab(_ mode: InteractionMode, _ symbol: String, _ title: String) -> some View {
        let selected = appState.currentMode == mode
        Button {
            if appState.currentMode != mode {
                UISelectionFeedbackGenerator().selectionChanged()
            }
            appState.setMode(mode)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        selected ? Color.white : Color.primary.opacity(0.9),
                        selected ? Color.white.opacity(0.9) : Color.primary.opacity(0.7)
                    )
                    .frame(width: 32, height: 32)

                // タイトルはコンパクトに固定幅で中央揃え
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .frame(width: 56) // 一定幅で配置
                    .foregroundColor(selected ? .white : .primary.opacity(0.8))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Group {
                    if selected {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.accentColor.gradient)
                            .shadow(color: Color.accentColor.opacity(0.28), radius: 10, x: 0, y: 6)
                    } else {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(inactiveFill)
                    }
                }
            )
            .contentShape(Rectangle())
            .animation(.spring(response: 0.28, dampingFraction: 0.86), value: selected)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tab_\(title)")
    }

    private var shadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.6) : .black.opacity(0.15)
    }
    private var inactiveFill: Color {
        colorScheme == .dark ? .white.opacity(0.06) : .black.opacity(0.04)
    }
}

// 共有の BlurView（AppBar と同実装）
private struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct BottomNavView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            BottomNavView(appState: AppState())
        }
        .background(
            LinearGradient(colors: [.blue.opacity(0.15), .purple.opacity(0.15)], startPoint: .top, endPoint: .bottom)
        )
        .preferredColorScheme(.light)

        VStack {
            Spacer()
            BottomNavView(appState: AppState())
        }
        .background(
            LinearGradient(colors: [.black, .indigo.opacity(0.35)], startPoint: .top, endPoint: .bottom)
        )
        .preferredColorScheme(.dark)
    }
}
