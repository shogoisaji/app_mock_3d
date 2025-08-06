import PhotosUI
import SwiftUI

struct ImagePickerView: View {
    @ObservedObject var imagePickerManager: ImagePickerManager
    @ObservedObject var permissionManager: PhotoPermissionManager
    
    var body: some View {
        VStack(spacing: 20) {
            if permissionManager.isAuthorized() {
                VStack(spacing: 16) {
                    // Display the currently selected image
                    if let selectedImage = imagePickerManager.selectedImage {
                        VStack(spacing: 12) {
                            Text("Selected Image")
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
                            
                            Text("No image selected")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Image selection button
                    PhotosPicker(
                        selection: $imagePickerManager.selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text(imagePickerManager.selectedImage == nil ? "Select Image" : "Select Another Image")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .onChange(of: imagePickerManager.selectedItem) { _, _ in
                        imagePickerManager.loadImage()
                    }
                    
                    // Button to clear the image
                    if imagePickerManager.selectedImage != nil {
                        Button(action: {
                            imagePickerManager.clearImage()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear Image")
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
                    
                    Text("Photo Library access is required")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("To select an image, please allow access to your photo library.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Button("Allow Access") {
                        Task {
                            let status = await permissionManager.requestPermission()
                            if status != .authorized {
                                print("Photo Library access was denied")
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
