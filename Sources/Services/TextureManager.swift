import SceneKit
import SwiftUI
import UIKit

class TextureManager {
    static let shared = TextureManager()
    
    private let textureCache = NSCache<NSString, SCNMaterial>()
    private let maxCacheSize = 50 * 1024 * 1024 // 50MB
    
    private init() {
        textureCache.totalCostLimit = maxCacheSize
        textureCache.countLimit = 100
    }
    
    func applyTextureToModel(_ model: SCNScene, image: UIImage) -> SCNScene? {
        // モデルのコピーを作成
        guard let modelCopy = model.copy() as? SCNScene else {
            return nil
        }
        
        // すべてのジオメトリにテクスチャを適用
        modelCopy.rootNode.enumerateChildNodes { (node, _) in
            if let geometry = node.geometry {
                for i in 0..<geometry.materials.count {
                    let material = geometry.materials[i]
                    material.diffuse.contents = image
                    geometry.materials[i] = material
                }
            }
        }
        
        return modelCopy
    }
    
    func applyTextureToModel(_ model: SCNScene, imageData: Data) -> SCNScene? {
        guard let image = UIImage(data: imageData) else {
            return nil
        }
        
        return applyTextureToModel(model, image: image)
    }
    
    func clearCache() {
        textureCache.removeAllObjects()
    }
}
