import SwiftUI

/// A performant checkerboard background commonly used to indicate transparency.
struct CheckerboardBackground: View {
    var lightColor: Color = Color(white: 0.95)
    var darkColor: Color = Color(white: 0.85)
    var squareSize: CGFloat = 12
    
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let w = size.width
                let h = size.height
                let s = max(4, squareSize)
                let cols = Int(ceil(w / s))
                let rows = Int(ceil(h / s))
                
                var lightPath = Path()
                var darkPath = Path()
                
                for r in 0..<rows {
                    for c in 0..<cols {
                        let rect = CGRect(x: CGFloat(c) * s, y: CGFloat(r) * s, width: s, height: s)
                        if (r + c) % 2 == 0 {
                            lightPath.addRect(rect)
                        } else {
                            darkPath.addRect(rect)
                        }
                    }
                }
                context.fill(lightPath, with: .color(lightColor))
                context.fill(darkPath, with: .color(darkColor))
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        CheckerboardBackground()
            .ignoresSafeArea()
        Text(NSLocalizedString("transparent", comment: ""))
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
