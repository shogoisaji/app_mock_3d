import PhotosUI
import SwiftUI
import UIKit

class ImagePickerManager: ObservableObject {
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
    }
}
