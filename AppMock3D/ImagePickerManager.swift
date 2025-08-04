import PhotosUI
import SwiftUI
import UIKit

class ImagePickerManager: ObservableObject {
    @Published var selectedItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var isPresented: Bool = false
    
    func selectImage() {
        isPresented = true
    }
    
    func imageSelected(_ image: UIImage?) {
        selectedImage = image
        isPresented = false
    }
    
    func clearImage() {
        selectedImage = nil
        selectedItem = nil
    }
    
    func loadImage() {
        guard let item = selectedItem else { return }
        
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let uiImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.selectedImage = uiImage
                    }
                }
            case .failure(let error):
                print("Error loading image: \(error)")
            }
        }
    }
}
