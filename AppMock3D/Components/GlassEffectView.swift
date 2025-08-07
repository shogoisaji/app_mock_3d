import SwiftUI

/// 再利用可能なガラス効果コンポーネント
struct GlassEffectView: View {
    let cornerRadius: CGFloat
    let borderLineWidth: CGFloat
    let shadowRadius: CGFloat
    let shadowOffset: CGSize
    let intensity: GlassIntensity
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        cornerRadius: CGFloat = 20,
        borderLineWidth: CGFloat = 0.1,
        shadowRadius: CGFloat = 16,
        shadowOffset: CGSize = CGSize(width: 0, height: 8),
        intensity: GlassIntensity = .medium
    ) {
        self.cornerRadius = cornerRadius
        self.borderLineWidth = borderLineWidth
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
        self.intensity = intensity
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        glassColor.opacity(colorScheme == .dark ? intensity.darkBackgroundStart : intensity.lightBackgroundStart),
                        glassColor.opacity(colorScheme == .dark ? intensity.darkBackgroundEnd : intensity.lightBackgroundEnd),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            // .background(
            //     // 追加のガラス色レイヤー
            //     RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            //         .fill(glassColor.opacity(0.1))
            // )
            // 背景にぼかし効果を追加して、よりリアルなガラス感を演出
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                // Glass-like inner highlight
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        highlightGradient,
                        lineWidth: borderLineWidth
                    )
            )
            .overlay(
                // Outer border - より強いボーダー
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: borderLineWidth)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: shadowOffset.width, y: shadowOffset.height)
            .shadow(color: shadowColor.opacity(0.5), radius: shadowRadius * 0.25, x: shadowOffset.width * 0.25, y: shadowOffset.height * 0.25)
    }
    
    // MARK: - Computed Properties
    
    
    private var highlightGradient: LinearGradient {
        LinearGradient(
            colors: [
                glassColor.opacity(colorScheme == .dark ? intensity.darkHighlightStart : intensity.lightHighlightStart),
                glassColor.opacity(colorScheme == .dark ? intensity.darkHighlightEnd : intensity.lightHighlightEnd),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var borderColor: Color {
        colorScheme == .dark
            ? Color.gray.opacity(intensity.darkBorderOpacity)
            : .white.opacity(intensity.lightBorderOpacity)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? .black.opacity(intensity.darkShadowOpacity) : .black.opacity(intensity.lightShadowOpacity)
    }
    
    
    private var glassColor: Color {
        Color(red: 0.85, green: 0.85, blue: 0.85) // #D9D9D9
    }
}

/// ガラス効果の強度設定
enum GlassIntensity {
    case subtle
    case medium
    case strong
    
    var darkBackgroundStart: Double {
        switch self {
        case .subtle: return 0.10
        case .medium: return 0.15
        case .strong: return 0.25
        }
    }
    
    var darkBackgroundEnd: Double {
        switch self {
        case .subtle: return 0.05
        case .medium: return 0.08
        case .strong: return 0.12
        }
    }
    
    var lightBackgroundStart: Double {
        switch self {
        case .subtle: return 0.15
        case .medium: return 0.20
        case .strong: return 0.30
        }
    }
    
    var lightBackgroundEnd: Double {
        switch self {
        case .subtle: return 0.10
        case .medium: return 0.15
        case .strong: return 0.20
        }
    }
    
    var darkHighlightStart: Double {
        switch self {
        case .subtle: return 0.4
        case .medium: return 0.6
        case .strong: return 0.8
        }
    }
    
    var darkHighlightEnd: Double {
        switch self {
        case .subtle: return 0.15
        case .medium: return 0.25
        case .strong: return 0.35
        }
    }
    
    var lightHighlightStart: Double {
        switch self {
        case .subtle: return 0.5
        case .medium: return 0.7
        case .strong: return 0.9
        }
    }
    
    var lightHighlightEnd: Double {
        switch self {
        case .subtle: return 0.2
        case .medium: return 0.3
        case .strong: return 0.4
        }
    }
    
    var darkBorderOpacity: Double {
        switch self {
        case .subtle: return 0.25
        case .medium: return 0.35
        case .strong: return 0.45
        }
    }
    
    var lightBorderOpacity: Double {
        switch self {
        case .subtle: return 0.15
        case .medium: return 0.25
        case .strong: return 0.35
        }
    }
    
    var darkShadowOpacity: Double {
        switch self {
        case .subtle: return 0.2
        case .medium: return 0.3
        case .strong: return 0.4
        }
    }
    
    var lightShadowOpacity: Double {
        switch self {
        case .subtle: return 0.05
        case .medium: return 0.08
        case .strong: return 0.12
        }
    }
}

// MARK: - Preview
struct GlassEffectView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            HStack(spacing: 20) {
                VStack {
                    Text("Subtle")
                        .font(.caption)
                    GlassEffectView(intensity: .subtle)
                        .frame(width: 100, height: 60)
                }
                
                VStack {
                    Text("Medium")
                        .font(.caption)
                    GlassEffectView(intensity: .medium)
                        .frame(width: 100, height: 60)
                }
                
                VStack {
                    Text("Strong")
                        .font(.caption)
                    GlassEffectView(intensity: .strong)
                        .frame(width: 100, height: 60)
                }
            }
            
            // Button sized example
            GlassEffectView(cornerRadius: 12, intensity: .medium)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                )
        }
        .padding(40)
        .background(
            LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .top, endPoint: .bottom)
        )
        .preferredColorScheme(.light)
        
        VStack(spacing: 30) {
            HStack(spacing: 20) {
                GlassEffectView(intensity: .subtle)
                    .frame(width: 100, height: 60)
                GlassEffectView(intensity: .medium)
                    .frame(width: 100, height: 60)
                GlassEffectView(intensity: .strong)
                    .frame(width: 100, height: 60)
            }
        }
        .padding(40)
        .background(
            LinearGradient(colors: [.black, .indigo.opacity(0.35)], startPoint: .top, endPoint: .bottom)
        )
        .preferredColorScheme(.dark)
    }
}