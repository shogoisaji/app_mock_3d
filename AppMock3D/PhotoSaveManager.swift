import Photos
import UIKit
import Combine

class PhotoSaveManager: ObservableObject {
    /// Save UIImage to the photo library. If preferPNG is true, writes PNG data to a temporary file
    /// and uses creationRequestForAssetFromImage(atFileURL:) to preserve alpha.
    func saveImageToPhotoLibrary(_ image: UIImage, preferPNG: Bool = false, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    if preferPNG, let data = image.pngData() {
                        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("export_\(UUID().uuidString).png")
                        do {
                            try data.write(to: tmpURL, options: .atomic)
                        } catch {
                            completion(false, error)
                            return
                        }
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: tmpURL)
                        }) { success, error in
                            // Clean up temp file
                            try? FileManager.default.removeItem(at: tmpURL)
                            completion(success, error)
                        }
                    } else {
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAsset(from: image)
                        }) { success, error in
                            completion(success, error)
                        }
                    }
                case .denied, .restricted:
                    completion(false, NSError(domain: "PhotoSaveManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Access to the photo library was denied."]))
                case .notDetermined:
                    completion(false, NSError(domain: "PhotoSaveManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Access to the photo library has not yet been granted."]))
                case .limited:
                    completion(false, NSError(domain: "PhotoSaveManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Limited access to the photo library is permitted."]))
                @unknown default:
                    completion(false, NSError(domain: "PhotoSaveManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unknown authorization status."]))
                }
            }
        }
    }
}
