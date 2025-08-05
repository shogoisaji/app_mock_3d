import SwiftUI

// 旧実装との衝突を避けるため、型名を変更（実体は未使用に誘導）
struct LegacyBottomNavView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        EmptyView()
    }
}

struct LegacyBottomNavView_Previews: PreviewProvider {
    static var previews: some View {
        LegacyBottomNavView(appState: AppState())
    }
}
