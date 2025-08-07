import SwiftUI

struct BottomAppBarView: View {
    var onGridToggle: () -> Void
    var onLightingAdjust: () -> Void
    var onResetTransform: () -> Void
    var onSettings: () -> Void
    // Added to display the current lighting number (1-4)
    var lightingNumber: Int = 1
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            GlassContainer(cornerRadius: 20, intensity: .medium) {
                HStack(spacing: 12) {
                    // Settings Button
                    GlassButton(
                        symbol: "gearshape",
                        action: onSettings,
                        accessibilityId: "gear",
                        size: 36,
                        cornerRadius: 12
                    )

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
            BottomAppBarView(onGridToggle: {}, onLightingAdjust: {}, onResetTransform: {}, onSettings: {})
        }
        .padding(.bottom, 20)
        .background(
            LinearGradient(colors: [.blue.opacity(0.15), .purple.opacity(0.15)], startPoint: .top, endPoint: .bottom)
        )
        .preferredColorScheme(.light)
        
        VStack {
            Spacer()
            BottomAppBarView(onGridToggle: {}, onLightingAdjust: {}, onResetTransform: {}, onSettings: {})
        }
        .padding(.bottom, 20)
        .background(
            LinearGradient(colors: [.black, .indigo.opacity(0.35)], startPoint: .top, endPoint: .bottom)
        )
        .preferredColorScheme(.dark)
    }
}