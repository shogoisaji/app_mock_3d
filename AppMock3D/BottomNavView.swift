import SwiftUI

struct BottomNavView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 0) {
            NavButton(iconName: "arrow.up.left.and.arrow.down.right", title: "移動", isSelected: appState.currentMode == .move) {
                appState.setMode(.move)
            }
            NavButton(iconName: "arrow.up.left.arrow.down.right", title: "拡大縮小", isSelected: appState.currentMode == .scale) {
                appState.setMode(.scale)
            }
            NavButton(iconName: "rotate.3d", title: "回転", isSelected: appState.currentMode == .rotate) {
                appState.setMode(.rotate)
            }
            NavButton(iconName: "rectangle.ratio", title: "アスペクト比", isSelected: appState.currentMode == .aspect) {
                appState.setMode(.aspect)
            }
            NavButton(iconName: "photo", title: "背景", isSelected: appState.currentMode == .background) {
                appState.setMode(.background)
            }
            NavButton(iconName: "iphone", title: "端末", isSelected: appState.currentMode == .device) {
                appState.setMode(.device)
            }
        }
        .frame(height: 72)
        .background(Color(.systemBackground))
        .shadow(radius: 8)
    }
}

struct NavButton: View {
    var iconName: String
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .foregroundColor(isSelected ? .white : .blue)
                    .font(.title2)
                    .frame(width: 30, height: 30)
                    .background(isSelected ? Color.blue : Color.clear)
                    .cornerRadius(4)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BottomNavView_Previews: PreviewProvider {
    static var previews: some View {
        BottomNavView(appState: AppState())
    }
}
