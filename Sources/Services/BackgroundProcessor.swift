import SceneKit
import UIKit

class BackgroundProcessor {
    enum BackgroundType {
        case transparent
        case solidColor(UIColor)
        case linearGradient(UIColor, UIColor)
        case radialGradient(UIColor, UIColor)
    }
    
    func applyBackground(to scene: SCNScene, type: BackgroundType) {
        switch type {
        case .transparent:
            scene.background.contents = nil
        case .solidColor(let color):
            scene.background.contents = color
        case .linearGradient(let startColor, let endColor):
            let gradientImage = createLinearGradientImage(startColor: startColor, endColor: endColor)
            scene.background.contents = gradientImage
        case .radialGradient(let startColor, let endColor):
            let gradientImage = createRadialGradientImage(startColor: startColor, endColor: endColor)
            scene.background.contents = gradientImage
        }
    }
    
    private func createLinearGradientImage(startColor: UIColor, endColor: UIColor) -> UIImage {
        let size = CGSize(width: 1024, height: 1024)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [startColor.cgColor, endColor.cgColor] as CFArray,
                                 locations: [0, 1])
        
        context?.drawLinearGradient(gradient!,
                                   start: CGPoint(x: 0, y: 0),
                                   end: CGPoint(x: size.width, y: size.height),
                                   options: [])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    private func createRadialGradientImage(startColor: UIColor, endColor: UIColor) -> UIImage {
        let size = CGSize(width: 1024, height: 1024)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [startColor.cgColor, endColor.cgColor] as CFArray,
                                 locations: [0, 1])
        
        context?.drawRadialGradient(gradient!,
                                   startCenter: CGPoint(x: size.width/2, y: size.height/2),
                                   startRadius: 0,
                                   endCenter: CGPoint(x: size.width/2, y: size.height/2),
                                   endRadius: size.width/2,
                                   options: [])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
