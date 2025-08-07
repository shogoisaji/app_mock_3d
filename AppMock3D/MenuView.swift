import SwiftUI

struct MenuView: View {
    @ObservedObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Menu")
                .font(.title)
                .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    // App info section with glass effect
                    GlassContainer(cornerRadius: 16, intensity: .subtle) {
                        VStack(spacing: 8) {
                            Image(systemName: "app.badge")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.accentColor)
                            
                            Text("AppMock3D")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("3D Model Mockup Generator")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    
                    // Menu Items with glass effect
                    GlassContainer(cornerRadius: 16, intensity: .subtle) {
                        VStack(spacing: 0) {
                            GlassMenuItemButton(
                                icon: "doc.text",
                                title: "プライバシーポリシー",
                                subtitle: "Privacy Policy",
                                action: {},
                                accessibilityId: "privacyPolicy"
                            )
                            
                            Divider().padding(.horizontal, 20)
                            
                            GlassMenuItemButton(
                                icon: "doc.plaintext",
                                title: "利用規約",
                                subtitle: "Terms of Service",
                                action: {},
                                accessibilityId: "termsOfService"
                            )
                            
                            Divider().padding(.horizontal, 20)
                            
                            GlassMenuItemButton(
                                icon: "envelope",
                                title: "お問い合わせ",
                                subtitle: "Contact",
                                action: { openMail() },
                                accessibilityId: "contact"
                            )
                            
                            Divider().padding(.horizontal, 20)
                            
                            GlassMenuItemButton(
                                icon: "info.circle",
                                title: "バージョン",
                                subtitle: "Version \(getAppVersion())",
                                action: {},
                                accessibilityId: "version"
                            )
                            
                            Divider().padding(.horizontal, 20)
                            
                            GlassMenuItemButton(
                                icon: "globe",
                                title: "言語設定",
                                subtitle: "Language Settings",
                                action: {},
                                accessibilityId: "languageSettings"
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(hex: "#B3B3B3"))
        .cornerRadius(24)
        .shadow(radius: 5)
        .tint(Color(hex: "#E99370") ?? .orange)
    }
    
    private func getAppVersion() -> String {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            return "\(version) (\(build))"
        }
        return "1.0.0"
    }
    
    private func openMail() {
        if let url = URL(string: "mailto:support@appmock3d.com") {
            UIApplication.shared.open(url)
        }
    }
}

private struct GlassMenuItemButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    let accessibilityId: String
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                // Icon with glass background
                ZStack {
                    GlassEffectView(
                        cornerRadius: 8,
                        borderLineWidth: 0.5,
                        shadowRadius: 3,
                        shadowOffset: CGSize(width: 0, height: 1),
                        intensity: .medium
                    )
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.accentColor)
                }
                .frame(width: 32, height: 32)
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .accessibilityIdentifier(accessibilityId)
    }
}

#Preview {
    MenuView(appState: AppState())
}