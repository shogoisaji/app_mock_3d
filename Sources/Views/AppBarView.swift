import SwiftUI

struct AppBarView: View {
    var title: String
    var onSave: () -> Void
    var onSettings: () -> Void
    
    var body: some View {
        HStack {
            // タイトルを非表示化
            
            Spacer()
            
            Button(action: onSave) {
                Image(systemName: "square.and.arrow.down")
                    .foregroundColor(.blue)
            }
            .padding(.trailing, 8)
            .accessibilityIdentifier("save")
            
            Button(action: onSettings) {
                Image(systemName: "gear")
                    .foregroundColor(.blue)
            }
            .accessibilityIdentifier("gear")
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color(.systemBackground))
        .shadow(radius: 4)
        // タイトル文字列に依存しない識別子に変更
        .accessibilityIdentifier("AppBar")
    }
}

struct AppBarView_Previews: PreviewProvider {
    static var previews: some View {
        AppBarView(title: "", onSave: {}, onSettings: {})
    }
}
