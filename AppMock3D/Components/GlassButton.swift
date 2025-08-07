import SwiftUI

/// ガラス効果を適用したボタンコンポーネント
struct GlassButton: View {
    let symbol: String
    let action: () -> Void
    let accessibilityId: String
    let size: CGFloat
    let cornerRadius: CGFloat
    let intensity: GlassIntensity
    
    @State private var pressed = false
    
    init(
        symbol: String,
        action: @escaping () -> Void,
        accessibilityId: String,
        size: CGFloat = 36,
        cornerRadius: CGFloat = 12,
        intensity: GlassIntensity = .medium
    ) {
        self.symbol = symbol
        self.action = action
        self.accessibilityId = accessibilityId
        self.size = size
        self.cornerRadius = cornerRadius
        self.intensity = intensity
    }
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            action()
        }) {
            ZStack {
                GlassEffectView(
                    cornerRadius: cornerRadius,
                    borderLineWidth: 0.6,
                    shadowRadius: 6,
                    shadowOffset: CGSize(width: 0, height: 3),
                    intensity: intensity
                )
                
                Image(systemName: symbol)
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.primary)
            }
            .frame(width: size, height: size)
            .scaleEffect(pressed ? 0.94 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: pressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !pressed { pressed = true }
                }
                .onEnded { _ in
                    pressed = false
                }
        )
        .accessibilityIdentifier(accessibilityId)
    }
}

/// より大きなガラスボタン（テキスト付き）
struct GlassLabelButton: View {
    let text: String
    let symbol: String?
    let action: () -> Void
    let accessibilityId: String
    let height: CGFloat
    let cornerRadius: CGFloat
    let intensity: GlassIntensity
    
    @State private var pressed = false
    
    init(
        text: String,
        symbol: String? = nil,
        action: @escaping () -> Void,
        accessibilityId: String,
        height: CGFloat = 44,
        cornerRadius: CGFloat = 16,
        intensity: GlassIntensity = .medium
    ) {
        self.text = text
        self.symbol = symbol
        self.action = action
        self.accessibilityId = accessibilityId
        self.height = height
        self.cornerRadius = cornerRadius
        self.intensity = intensity
    }
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            action()
        }) {
            ZStack {
                GlassEffectView(
                    cornerRadius: cornerRadius,
                    borderLineWidth: 0.8,
                    shadowRadius: 8,
                    shadowOffset: CGSize(width: 0, height: 4),
                    intensity: intensity
                )
                
                HStack(spacing: 8) {
                    if let symbol = symbol {
                        Image(systemName: symbol)
                            .font(.system(size: 16, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                    }
                    
                    Text(text)
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
            }
            .frame(height: height)
            .scaleEffect(pressed ? 0.96 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: pressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !pressed { pressed = true }
                }
                .onEnded { _ in
                    pressed = false
                }
        )
        .accessibilityIdentifier(accessibilityId)
    }
}

/// ガラス効果のコンテナ（複数のボタンをまとめる）
struct GlassContainer<Content: View>: View {
    let cornerRadius: CGFloat
    let intensity: GlassIntensity
    let content: Content
    
    init(
        cornerRadius: CGFloat = 20,
        intensity: GlassIntensity = .medium,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.intensity = intensity
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            GlassEffectView(
                cornerRadius: cornerRadius,
                borderLineWidth: 0.8,
                shadowRadius: 12,
                shadowOffset: CGSize(width: 0, height: 6),
                intensity: intensity
            )
            
            content
        }
    }
}

// MARK: - Preview
struct GlassButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Individual buttons
            HStack(spacing: 20) {
                GlassButton(symbol: "gearshape", action: {}, accessibilityId: "gear", intensity: .subtle)
                GlassButton(symbol: "photo", action: {}, accessibilityId: "photo", intensity: .medium)
                GlassButton(symbol: "square.and.arrow.down", action: {}, accessibilityId: "save", intensity: .strong)
            }
            
            // Container with buttons
            GlassContainer(intensity: .medium) {
                HStack(spacing: 12) {
                    GlassButton(symbol: "gearshape", action: {}, accessibilityId: "gear")
                    GlassButton(symbol: "photo", action: {}, accessibilityId: "photo")
                    GlassButton(symbol: "square.and.arrow.down", action: {}, accessibilityId: "save")
                }
                .padding(16)
            }
            .fixedSize()
            
            // Label buttons
            VStack(spacing: 12) {
                GlassLabelButton(text: "設定", symbol: "gearshape", action: {}, accessibilityId: "settings")
                GlassLabelButton(text: "写真を選択", symbol: "photo", action: {}, accessibilityId: "selectPhoto")
                GlassLabelButton(text: "保存", action: {}, accessibilityId: "save")
            }
            .padding(.horizontal)
        }
        .padding(40)
        .background(
            LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .top, endPoint: .bottom)
        )
        .preferredColorScheme(.light)
        
        VStack(spacing: 30) {
            HStack(spacing: 20) {
                GlassButton(symbol: "gearshape", action: {}, accessibilityId: "gear")
                GlassButton(symbol: "photo", action: {}, accessibilityId: "photo")
                GlassButton(symbol: "square.and.arrow.down", action: {}, accessibilityId: "save")
            }
            
            GlassLabelButton(text: "ダークモードテスト", symbol: "moon.fill", action: {}, accessibilityId: "dark")
                .padding(.horizontal)
        }
        .padding(40)
        .background(
            LinearGradient(colors: [.black, .indigo.opacity(0.35)], startPoint: .top, endPoint: .bottom)
        )
        .preferredColorScheme(.dark)
    }
}