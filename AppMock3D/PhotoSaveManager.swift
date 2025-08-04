import Photos
import UIKit

class PhotoSaveManager {
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
                    completion(false, NSError(domain: "PhotoSaveManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "写真ライブラリへのアクセスが拒否されました"]))
                case .notDetermined:
                    completion(false, NSError(domain: "PhotoSaveManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "写真ライブラリへのアクセスがまだ許可されていません"]))
                case .limited:
                    completion(false, NSError(domain: "PhotoSaveManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "限定的な写真ライブラリへのアクセスが許可されています"]))
                @unknown default:
                    completion(false, NSError(domain: "PhotoSaveManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "不明なアクセス許可ステータス"]))
                }
            }
        }
    }
}
