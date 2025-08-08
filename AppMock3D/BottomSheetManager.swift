import SwiftUI
import UIKit

struct BottomSheetManager<Content: View>: View {
    @Binding var isOpen: Bool
    var content: Content
    // 視覚的にバーの下端と一致させるには外側 12pt のみ（内側 6pt はビュー枠内のインセット）
    var bottomSpacing: CGFloat = 12
    
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background overlay
                if isOpen {
                    Color.black
                        .opacity(0.3)
                        .onTapGesture {
                            isOpen = false
                        }
                        .edgesIgnoringSafeArea(.all)
                }
                
                // Bottom sheet
                VStack(spacing: 0) {
                    Spacer()
                    if isOpen {
                        VStack(spacing: 0) {
                            // // Drag handle
                            // Rectangle()
                            //     .fill(Color.gray)
                            //     .frame(width: 40, height: 5)
                            //     .cornerRadius(2.5)
                            //     .padding(.top, 10)
                            //     .padding(.bottom, 10)
                            
                            // Content
                            content
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 16)
                        }
                        // 高さは可変（必要分だけ）。上限は画面の80%に制限。
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: geometry.size.height * 0.8, alignment: .bottom)
                        // .background(Color(.secondarySystemBackground))
                        .cornerRadius(20, corners: [.topLeft, .topRight])
                        .shadow(radius: 10)
                        .offset(y: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation.height > 0 ? value.translation.height : 0
                                }
                                .onEnded { value in
                                    if value.translation.height > 100 {
                                        isOpen = false
                                    }
                                    dragOffset = 0
                                }
                        )
                        .animation(.easeInOut(duration: 0.3), value: dragOffset)
                        .transition(.move(edge: .bottom))
                    }
                }
                // シート全体の底辺位置を Bottom App Bar の 12pt 外側パディングに合わせる
                .padding(.bottom, bottomSpacing)
            }
        }
        .background(Color.clear)
        .zIndex(1)
    }
}

// Extension to add corner radius to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// Custom shape for corner radius
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
