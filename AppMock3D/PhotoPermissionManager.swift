import PhotosUI
import SwiftUI

class PhotoPermissionManager: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func requestPermission() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        return status
    }
    
    func isAuthorized() -> Bool {
        return authorizationStatus == .authorized
    }
}
