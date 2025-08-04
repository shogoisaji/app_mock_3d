import SwiftUI
import UIKit

class ImageProcessingService {
    static let shared = ImageProcessingService()
    
    private init() {}
    
    func resizeImage(_ image: UIImage, maxWidth: CGFloat = 4096) -> UIImage? {
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        
        // すでに最大幅以下であればそのまま返す
        if originalWidth <= maxWidth {
            return image
        }
        
        // アスペクト比を維持してリサイズ
        let aspectRatio = originalHeight / originalWidth
        let newSize = CGSize(width: maxWidth, height: maxWidth * aspectRatio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    func convertToPNG(_ image: UIImage) -> Data? {
        return image.pngData()
    }
}
