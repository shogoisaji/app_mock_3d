import PhotosUI
import SwiftUI

struct ImagePickerView: View {
    @ObservedObject var imagePickerManager: ImagePickerManager
    @ObservedObject var permissionManager: PhotoPermissionManager
    
    var body: some View {
        VStack(spacing: 20) {
            if permissionManager.isAuthorized() {
                VStack(spacing: 16) {
                    // 現在選択されている画像を表示
                    if let selectedImage = imagePickerManager.selectedImage {
                        VStack(spacing: 12) {
                            Text("選択中の画像")
                                .font(.headline)
                            
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.circle")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                            
                            Text("画像が選択されていません")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // 画像選択ボタン
                    PhotosPicker(
                        selection: $imagePickerManager.selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text(imagePickerManager.selectedImage == nil ? "画像を選択" : "別の画像を選択")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .onChange(of: imagePickerManager.selectedItem) { _, _ in
                        imagePickerManager.loadImage()
                    }
                    
                    // 画像をクリアするボタン
                    if imagePickerManager.selectedImage != nil {
                        Button(action: {
                            imagePickerManager.clearImage()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("画像をクリア")
                            }
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("写真ライブラリへのアクセス権限が必要です")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("画像を選択するために、写真ライブラリへのアクセスを許可してください。")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Button("アクセスを許可") {
                        Task {
                            let status = await permissionManager.requestPermission()
                            if status != .authorized {
                                print("写真ライブラリへのアクセスが拒否されました")
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .onAppear {
            permissionManager.checkAuthorizationStatus()
        }
    }
}

struct ImagePickerView_Previews: PreviewProvider {
    static var previews: some View {
        ImagePickerView(imagePickerManager: ImagePickerManager(), permissionManager: PhotoPermissionManager())
    }
}
