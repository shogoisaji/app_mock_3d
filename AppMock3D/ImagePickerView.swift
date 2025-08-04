import PhotosUI
import SwiftUI

struct ImagePickerView: View {
    @ObservedObject var imagePickerManager: ImagePickerManager
    @ObservedObject var permissionManager: PhotoPermissionManager
    
    var body: some View {
        VStack {
            if permissionManager.isAuthorized() {
                PhotosPicker("写真を選択", selection: $imagePickerManager.selectedItem, matching: .images)
                    .onChange(of: imagePickerManager.selectedItem) { _ in
                        imagePickerManager.loadImage()
                    }
            } else {
                Button("写真ライブラリへのアクセスを許可") {
                    Task {
                        let status = await permissionManager.requestPermission()
                        if status != .authorized {
                            // 権限が拒否された場合の処理
                            print("写真ライブラリへのアクセスが拒否されました")
                        }
                    }
                }
            }
        }
    }
}

struct ImagePickerView_Previews: PreviewProvider {
    static var previews: some View {
        ImagePickerView(imagePickerManager: ImagePickerManager(), permissionManager: PhotoPermissionManager())
    }
}
