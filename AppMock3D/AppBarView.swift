import SwiftUI

struct AppBarView: View {
    var title: String
    var onSave: () -> Void
    var onSettings: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
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
        .accessibilityIdentifier(title)
    }
}

struct AppBarView_Previews: PreviewProvider {
    static var previews: some View {
        AppBarView(title: "AppMock3D", onSave: {}, onSettings: {})
    }
}
