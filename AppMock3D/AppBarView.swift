import SwiftUI

struct AppBarView: View {
    var title: String
    var onSave: () -> Void
    var onImageSelect: () -> Void
    var onMenu: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            // Left side: Hamburger Menu Button
            GlassContainer(cornerRadius: 20, intensity: .medium) {
                GlassButton(
                    symbol: "line.3.horizontal",
                    action: onMenu,
                    accessibilityId: "menu",
                    size: 36,
                    cornerRadius: 12
                )
                .padding(.horizontal, 16)
            }
            .frame(height: 60)
            .fixedSize(horizontal: true, vertical: false)
            
            Spacer(minLength: 0)

            // Right side: Existing buttons
            GlassContainer(cornerRadius: 20, intensity: .medium) {
                HStack(spacing: 12) {
                    GlassButton(
                        symbol: "photo",
                        action: onImageSelect,
                        accessibilityId: "imageSelect",
                        size: 36,
                        cornerRadius: 12
                    )
                    
                    GlassButton(
                        symbol: "square.and.arrow.down",
                        action: onSave,
                        accessibilityId: "save",
                        size: 36,
                        cornerRadius: 12
                    )
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 60)
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 12) // Padding from screen edge
        .padding(.top, 6)
        .accessibilityIdentifier("AppBar")
    }

}


struct AppBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AppBarView(title: "タイトル", onSave: {}, onImageSelect: {}, onMenu: {})
            Spacer()
        }
        .padding(.top, 20)
        .background(
            LinearGradient(colors: [.blue.opacity(0.15), .purple.opacity(0.15)], startPoint: .top, endPoint: .bottom)
        )
        .preferredColorScheme(.light)

        VStack {
            AppBarView(title: "タイトル", onSave: {}, onImageSelect: {}, onMenu: {})
            Spacer()
        }
        .padding(.top, 20)
        .background(
            LinearGradient(colors: [.black, .indigo.opacity(0.35)], startPoint: .top, endPoint: .bottom)
        )
        .preferredColorScheme(.dark)
    }
}
