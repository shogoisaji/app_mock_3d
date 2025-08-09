import Photos
import UIKit
import Combine

class PhotoSaveManager: ObservableObject {
    func saveImageToPhotoLibrary(_ image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }) { success, error in
                        completion(success, error)
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

    func saveVideoToPhotoLibrary(from fileURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
                    }) { success, error in
                        // Clean up the temporary file
                        try? FileManager.default.removeItem(at: fileURL)
                        completion(success, error)
                    }
                case .denied, .restricted:
                    completion(false, NSError(domain: "PhotoSaveManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Access to the photo library was denied."]))
                case .notDetermined:
                    completion(false, NSError(domain: "PhotoSaveManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Access to the photo library has not yet been granted."]))
                case .limited:
                     PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
                    }) { success, error in
                        try? FileManager.default.removeItem(at: fileURL)
                        completion(success, error)
                    }
                @unknown default:
                    completion(false, NSError(domain: "PhotoSaveManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unknown authorization status."]))
                }
            }
        }
    }
}
