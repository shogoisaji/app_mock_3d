import SceneKit
import SwiftUI
import UIKit

class TextureManager {
    static let shared = TextureManager()
    
    private let textureCache = NSCache<NSString, SCNMaterial>()
    private let sceneCache = NSCache<NSString, SCNScene>()
    private let maxCacheSize = 50 * 1024 * 1024 // 50MB
    private var cachedOriginalScene: SCNScene?
    
    private init() {
        textureCache.totalCostLimit = maxCacheSize
        textureCache.countLimit = 100
        
        sceneCache.totalCostLimit = maxCacheSize
        sceneCache.countLimit = 10 // Limit the number of scenes
        
        // Monitor for memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        clearCache()
    }
    
    func applyTextureToModel(_ model: SCNScene, image: UIImage) -> SCNScene? {
        // Optimize the image (resize if necessary)
        let optimizedImage = optimizeImageForTexture(image)
        
        // Debug: Output image information
        print("=== Image Debug Info ===")
        print("Original image size: \(image.size)")
        print("Optimized image size: \(optimizedImage.size)")
        print("Image scale: \(optimizedImage.scale)")
        print("========================")
        
        // Modify the existing scene directly (do not create a new scene)
        let workingScene = model
        
        print("Using existing scene (no deep copy)")
        
        // Debug: Output node structure
        print("=== TextureManager: Scene Node Structure ===")
        debugSceneStructure(workingScene.rootNode, level: 0)
        print("=== End Scene Node Structure ===")
        
        // Apply texture only to the screen part of the iPhone model
        var screenFound = false
        var screenNodeCandidates: [(SCNNode, String)] = []
        
        workingScene.rootNode.enumerateChildNodes { (node, stop) in
            // Check node name and geometry existence
            let nodeName = node.name?.lowercased() ?? ""
            let hasGeometry = node.geometry != nil
            
            print("Checking node: '\(node.name ?? "unnamed")' (has geometry: \(hasGeometry))")
            
            // If geometry exists, output its details as well
            if hasGeometry, let geometry = node.geometry {
                print("  └─ Geometry type: \(type(of: geometry))")
                print("  └─ Materials count: \(geometry.materials.count)")
                if !geometry.materials.isEmpty {
                    for (index, material) in geometry.materials.enumerated() {
                        print("    └─ Material \(index): \(material.name ?? "unnamed")")
                    }
                }
            }
            
            // Identify the screen node (check for multiple possible names)
            let possibleScreenNames = ["screen", "Screen", "display", "Display", "LCD", "OLED", "Screen_Border", "Ellipse_2_Material"]
            
            let isScreenNode = possibleScreenNames.contains { screenName in
                nodeName.contains(screenName.lowercased())
            }
            
            if isScreenNode && hasGeometry {
                print("✓ Found screen node: '\(node.name ?? "unnamed")'")
                screenNodeCandidates.append((node, node.name ?? "unnamed"))
            } else if hasGeometry {
                // Even if it's not a screen name, add nodes with geometry as candidates
                screenNodeCandidates.append((node, node.name ?? "unnamed"))
                print("Added geometry node as candidate: '\(node.name ?? "unnamed")'")
            }
        }
        
        // Select the optimal screen node ("screen" has the highest priority, followed by "Screen_Border")
        if let screenNode = screenNodeCandidates.first(where: { $0.1.lowercased().contains("screen") && !$0.1.lowercased().contains("border") }) ??
                           screenNodeCandidates.first(where: { $0.1.lowercased().contains("screen_border") }) ??
                           screenNodeCandidates.first {
            
            print("Applying texture to screen node: '\(screenNode.1)'")
            screenFound = true
            
            if let geometry = screenNode.0.geometry {
                print("Screen node has \(geometry.materials.count) materials")
                
                // Debug: Output geometry information
                print("=== Geometry Debug Info ===")
                print("Geometry type: \(type(of: geometry))")
                let sources = geometry.sources
                for source in sources {
                    print("Source semantic: \(source.semantic.rawValue), vectorCount: \(source.vectorCount)")
                }
                print("===========================")
                
                // If it is a screen node, it is often a single material, so replace all
                if screenNode.1.lowercased().contains("screen") && geometry.materials.count == 1 {
                    // Create a new material and apply the texture
                    let screenMaterial = SCNMaterial()
                    
                    // Texture quality settings
                    screenMaterial.diffuse.contents = optimizedImage
                    screenMaterial.diffuse.wrapS = .clamp
                    screenMaterial.diffuse.wrapT = .clamp
                    screenMaterial.diffuse.minificationFilter = .linear
                    screenMaterial.diffuse.magnificationFilter = .linear
                    
                    // Accurate application of UV coordinates (the image is already pre-flipped)
                    // Adjust contentsTransform to correct for horizontal flipping
                    let transform = SCNMatrix4MakeScale(-1, 1, 1)
                    screenMaterial.diffuse.contentsTransform = SCNMatrix4Translate(transform, 1, 0, 0)
                    
                    // Add screen emission effect (for realistic display)
                    // Temporarily disable emission effect for testing
                    // screenMaterial.emission.contents = optimizedImage
                    // screenMaterial.emission.intensity = 0.1
                    
                    // Specular reflection settings
                    screenMaterial.specular.contents = UIColor.white
                    screenMaterial.shininess = 1.0
                    
                    // If it is a single material, replace all
                    geometry.materials = [screenMaterial]
                    print("Applied texture to single material screen node")
                    
                    // Debug: Check material settings
                    print("=== Material Debug Info ===")
                    print("diffuse.contents: \(screenMaterial.diffuse.contents != nil ? "Set" : "Not Set")")
                    print("emission.contents: \(screenMaterial.emission.contents != nil ? "Set" : "Not Set")")
                    print("diffuse.wrapS: \(screenMaterial.diffuse.wrapS.rawValue)")
                    print("diffuse.wrapT: \(screenMaterial.diffuse.wrapT.rawValue)")
                    if let image = screenMaterial.diffuse.contents as? UIImage {
                        print("Texture image size: \(image.size)")
                    }
                    print("==========================")
                } else {
                    // If there are multiple materials, identify the appropriate index
                    var targetMaterialIndex = -1
                    
                    for (index, material) in geometry.materials.enumerated() {
                        // Infer the screen part from the material name
                        if let materialName = material.name?.lowercased() {
                            if materialName.contains("screen") || materialName.contains("display") || materialName.contains("lcd") {
                                targetMaterialIndex = index
                                print("Found screen material at index \(index): \(materialName)")
                                break
                            }
                        }
                        
                        // Judgment by color (infer a dark color as the screen)
                        if let diffuseColor = material.diffuse.contents as? UIColor {
                            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                            diffuseColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                            let brightness = (red + green + blue) / 3.0
                            
                            if brightness < 0.3 { // Dark color (probably the screen)
                                targetMaterialIndex = index
                                print("Found dark material (likely screen) at index \(index): brightness=\(brightness)")
                                break
                            }
                        }
                    }
                    
                    // If a specific material is not found, use the first material
                    if targetMaterialIndex == -1 && !geometry.materials.isEmpty {
                        targetMaterialIndex = 0
                        print("Using first material as screen (index \(targetMaterialIndex))")
                    }
                    
                    if targetMaterialIndex >= 0 {
                        // Create a new material and apply the texture
                        let screenMaterial = SCNMaterial()
                        
                        // Texture quality settings
                        screenMaterial.diffuse.contents = optimizedImage
                        screenMaterial.diffuse.wrapS = .clamp
                        screenMaterial.diffuse.wrapT = .clamp
                        screenMaterial.diffuse.minificationFilter = .linear
                        screenMaterial.diffuse.magnificationFilter = .linear
                        
                        // Accurate application of UV coordinates (the image is already pre-flipped)
                        // Adjust contentsTransform to correct for horizontal flipping
                        let transform = SCNMatrix4MakeScale(-1, 1, 1)
                        screenMaterial.diffuse.contentsTransform = SCNMatrix4Translate(transform, 1, 0, 0)
                        
                        // Add screen emission effect (for realistic display)
                        // Temporarily disable emission effect for testing
                        // screenMaterial.emission.contents = optimizedImage
                        // screenMaterial.emission.intensity = 0.1
                        
                        // Specular reflection settings
                        screenMaterial.specular.contents = UIColor.white
                        screenMaterial.shininess = 1.0
                        
                        // Replace only the specific material index
                        geometry.materials[targetMaterialIndex] = screenMaterial
                        print("Applied texture to material index \(targetMaterialIndex)")
                    }
                }
            }
        } else if !screenNodeCandidates.isEmpty {
            // If no screen candidates are found, identify the screen part based on the material
            let node = screenNodeCandidates.first!.0
            if let geometry = node.geometry {
                print("Attempting material-based screen detection on '\(node.name ?? "unnamed")' with \(geometry.materials.count) materials")
                
                // Find a material suitable for the screen (usually black or dark, or with "screen" in the name)
                var targetMaterialIndex = -1
                
                for (index, material) in geometry.materials.enumerated() {
                    // Infer the screen part from the material color or name
                    if let materialName = material.name?.lowercased() {
                        if materialName.contains("screen") || materialName.contains("display") || materialName.contains("lcd") {
                            targetMaterialIndex = index
                            print("Found screen material at index \(index): \(materialName)")
                            break
                        }
                    }
                    
                    // Judgment by color (infer a dark color as the screen)
                    if let diffuseColor = material.diffuse.contents as? UIColor {
                        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                        diffuseColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                        let brightness = (red + green + blue) / 3.0
                        
                        if brightness < 0.3 { // Dark color (probably the screen)
                            targetMaterialIndex = index
                            print("Found dark material (likely screen) at index \(index): brightness=\(brightness)")
                            break
                        }
                    }
                }
                
                // If a specific material is not found, use the last material (usually the screen part)
                if targetMaterialIndex == -1 && !geometry.materials.isEmpty {
                    targetMaterialIndex = geometry.materials.count - 1
                    print("Using last material as screen (index \(targetMaterialIndex))")
                }
                
                if targetMaterialIndex >= 0 {
                    // Create a new material and apply the texture
                    let screenMaterial = SCNMaterial()
                    
                    // Texture quality settings
                    screenMaterial.diffuse.contents = optimizedImage
                    screenMaterial.diffuse.wrapS = .clamp
                    screenMaterial.diffuse.wrapT = .clamp
                    screenMaterial.diffuse.minificationFilter = .linear
                    screenMaterial.diffuse.magnificationFilter = .linear
                    
                    // Accurate application of UV coordinates
                    // Adjust contentsTransform to correct for horizontal flipping
                    let transform = SCNMatrix4MakeScale(-1, 1, 1)
                    screenMaterial.diffuse.contentsTransform = SCNMatrix4Translate(transform, 1, 0, 0)
                    
                    // Add screen emission effect (for realistic display)
                    // Temporarily disable emission effect for testing
                    // screenMaterial.emission.contents = optimizedImage
                    // screenMaterial.emission.intensity = 0.1
                    
                    // Specular reflection settings
                    screenMaterial.specular.contents = UIColor.white
                    screenMaterial.shininess = 1.0
                    
                    // Replace only the specific material index
                    geometry.materials[targetMaterialIndex] = screenMaterial
                    screenFound = true
                    
                    print("Applied texture to material index \(targetMaterialIndex)")
                }
            }
        }
        
        // Alternative processing if no screen node is found
        if !screenFound {
            print("⚠️ Warning: No screen node found with geometry from candidates: \(screenNodeCandidates.map { $0.1 })")
            print("Available nodes with geometry:")
            var geometryNodes: [(SCNNode, String)] = []
            
            workingScene.rootNode.enumerateChildNodes { (node, _) in
                if let geometry = node.geometry {
                    let nodeName = node.name ?? "unnamed"
                    geometryNodes.append((node, nodeName))
                    print("  - \(nodeName) (materials: \(geometry.materials.count))")
                }
            }
            
            // Find a larger geometry (probably the screen)
            if let largestNode = geometryNodes.max(by: { (node1, node2) in
                let bounds1 = node1.0.boundingBox
                let bounds2 = node2.0.boundingBox
                let volume1 = (bounds1.max.x - bounds1.min.x) * (bounds1.max.y - bounds1.min.y) * (bounds1.max.z - bounds1.min.z)
                let volume2 = (bounds2.max.x - bounds2.min.x) * (bounds2.max.y - bounds2.min.y) * (bounds2.max.z - bounds2.min.z)
                return volume1 < volume2
            }) {
                print("Applying texture to largest geometry node: '\(largestNode.1)' with \(largestNode.0.geometry?.materials.count ?? 0) materials")
                
                if let geometry = largestNode.0.geometry {
                    // Identify the appropriate material index even for the largest node
                    var targetMaterialIndex = -1
                    
                    for (index, material) in geometry.materials.enumerated() {
                        // Infer the screen part from the material name
                        if let materialName = material.name?.lowercased() {
                            if materialName.contains("screen") || materialName.contains("display") || materialName.contains("lcd") {
                                targetMaterialIndex = index
                                print("Found screen material at index \(index): \(materialName)")
                                break
                            }
                        }
                        
                        // Judgment by color (infer a dark color as the screen)
                        if let diffuseColor = material.diffuse.contents as? UIColor {
                            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                            diffuseColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                            let brightness = (red + green + blue) / 3.0
                            
                            if brightness < 0.3 { // Dark color (probably the screen)
                                targetMaterialIndex = index
                                print("Found dark material (likely screen) at index \(index): brightness=\(brightness)")
                                break
                            }
                        }
                    }
                    
                    // If a specific material is not found, use the last material (usually the screen part)
                    if targetMaterialIndex == -1 && !geometry.materials.isEmpty {
                        targetMaterialIndex = geometry.materials.count - 1
                        print("Using last material as screen (index \(targetMaterialIndex))")
                    }
                    
                    if targetMaterialIndex >= 0 {
                        let screenMaterial = SCNMaterial()
                        screenMaterial.diffuse.contents = optimizedImage
                        screenMaterial.diffuse.wrapS = .clamp
                        screenMaterial.diffuse.wrapT = .clamp
                        screenMaterial.diffuse.minificationFilter = .linear
                        screenMaterial.diffuse.magnificationFilter = .linear
                        // Adjust contentsTransform to correct for horizontal flipping
                        let transform = SCNMatrix4MakeScale(-1, 1, 1)
                        screenMaterial.diffuse.contentsTransform = SCNMatrix4Translate(transform, 1, 0, 0)
                        // Temporarily disable emission effect for testing
                        // screenMaterial.emission.contents = optimizedImage
                        // screenMaterial.emission.intensity = 0.05
                        screenMaterial.specular.contents = UIColor.white
                        screenMaterial.shininess = 1.0
                        
                        // Replace only the specific material index
                        geometry.materials[targetMaterialIndex] = screenMaterial
                        screenFound = true
                        print("Applied texture to material index \(targetMaterialIndex) of largest node")
                    }
                }
            }
        }
        
        // Error if screen node is not found
        guard screenFound else {
            print("Warning: Screen node not found in model")
            return nil
        }
        
        print("Successfully applied texture to existing scene")
        return workingScene
    }
    
    // Clear the image texture and return to the original state
    func clearTextureFromModel(_ model: SCNScene) -> SCNScene? {
        print("Clearing texture from existing scene")
        
        // Find the screen part of the iPhone model and return it to the original black screen
        var screenFound = false
        
        model.rootNode.enumerateChildNodes { (node, stop) in
            let nodeName = node.name?.lowercased() ?? ""
            let hasGeometry = node.geometry != nil
            
            if hasGeometry, let geometry = node.geometry {
                // Find screen node candidates
                let possibleScreenNames = ["screen", "Screen", "display", "Display", "LCD", "OLED", "Screen_Border", "Ellipse_2_Material"]
                let isScreenNode = possibleScreenNames.contains { screenName in
                    nodeName.contains(screenName.lowercased())
                }
                
                if isScreenNode || (!screenFound && hasGeometry) {
                    print("Clearing texture from node: '\(node.name ?? "unnamed")'")
                    
                    // Return the screen material to the original black screen
                    for (index, _) in geometry.materials.enumerated() {
                        let screenMaterial = SCNMaterial()
                        screenMaterial.diffuse.contents = UIColor.black
                        screenMaterial.specular.contents = UIColor.white
                        screenMaterial.shininess = 1.0
                        
                        geometry.materials[index] = screenMaterial
                    }
                    screenFound = true
                    stop.pointee = true
                }
            }
        }
        
        print("Successfully cleared texture from existing scene")
        return model
    }
    
    private func optimizeImageForTexture(_ image: UIImage) -> UIImage {
        // First, flip the image vertically
        let flippedImage = flipImageVertically(image)
        
        // Optimize the texture size (max 2048x2048)
        let maxSize: CGFloat = 2048
        let currentSize = flippedImage.size
        
        if currentSize.width <= maxSize && currentSize.height <= maxSize {
            return flippedImage
        }
        
        let scale = min(maxSize / currentSize.width, maxSize / currentSize.height)
        let newSize = CGSize(width: currentSize.width * scale, height: currentSize.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        flippedImage.draw(in: CGRect(origin: .zero, size: newSize))
        let optimizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? flippedImage
        UIGraphicsEndImageContext()
        
        return optimizedImage
    }
    
    private func flipImageVertically(_ image: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        
        let context = UIGraphicsGetCurrentContext()!
        
        // Flip the coordinate system vertically
        context.translateBy(x: 0, y: image.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        // Draw the image
        image.draw(at: .zero)
        
        let flippedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return flippedImage
    }
    
    func applyTextureToModel(_ model: SCNScene, imageData: Data) -> SCNScene? {
        guard let image = UIImage(data: imageData) else {
            return nil
        }
        
        return applyTextureToModel(model, image: image)
    }
    
    func clearCache() {
        textureCache.removeAllObjects()
        sceneCache.removeAllObjects()
        cachedOriginalScene = nil
    }
    
    func getCacheInfo() -> (textureCount: Int, sceneCount: Int) {
        // Get cache information for debugging
        return (textureCache.totalCostLimit, sceneCache.totalCostLimit)
    }
    
    
    private func debugSceneStructure(_ node: SCNNode, level: Int) {
        let indent = String(repeating: "  ", count: level)
        let nodeName = node.name ?? "unnamed"
        let hasGeometry = node.geometry != nil
        let materialCount = node.geometry?.materials.count ?? 0
        
        print("\(indent)- \(nodeName) (geometry: \(hasGeometry), materials: \(materialCount))")
        
        for child in node.childNodes {
            debugSceneStructure(child, level: level + 1)
        }
    }
}
