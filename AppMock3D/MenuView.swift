import SwiftUI

struct MenuView: View {
    @ObservedObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    
                    
                    // Menu Items with glass effect
                    GlassContainer(cornerRadius: 16, intensity: .subtle) {
                        VStack(spacing: 0) {
                            GlassMenuItemButton(
                                icon: "doc.text",
                                title: NSLocalizedString("privacy_policy", comment: "Privacy Policy"),
                                subtitle: "",
                                action: { openPrivacyPolicy() },
                                accessibilityId: "privacyPolicy"
                            )
                            
                            Divider().padding(.horizontal, 20)
                            
                            GlassMenuItemButton(
                                icon: "doc.plaintext",
                                title: NSLocalizedString("terms_of_service", comment: "Terms of Service"),
                                subtitle: "",
                                action: { openTermsOfService() },
                                accessibilityId: "termsOfService"
                            )
                            
                            Divider().padding(.horizontal, 20)
                            
                            GlassMenuItemButton(
                                icon: "envelope",
                                title: NSLocalizedString("contact", comment: "Contact"),
                                subtitle: "",
                                action: { openContact() },
                                accessibilityId: "contact"
                            )
                            
                            Divider().padding(.horizontal, 20)
                            
                            GlassMenuItemButton(
                                icon: "info.circle",
                                title: NSLocalizedString("version", comment: "Version"),
                                subtitle: getAppVersion(),
                                action: {},
                                accessibilityId: "version",
                                showChevron: false
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
    
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://app-mock-3d.isajiappdev.workers.dev/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openTermsOfService() {
        if let url = URL(string: "https://app-mock-3d.isajiappdev.workers.dev/terms") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openContact() {
        if let url = URL(string: "https://app-mock-3d.isajiappdev.workers.dev/contact") {
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
    let showChevron: Bool

    @State private var isPressed = false
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void,
        accessibilityId: String,
        showChevron: Bool = true
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.accessibilityId = accessibilityId
        self.showChevron = showChevron
    }
    
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
                
                // Arrow (optional)
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
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