import SceneKit
import SwiftUI
import UIKit

class TextureManager {
    static let shared = TextureManager()
    
    private let textureCache = NSCache<NSString, SCNMaterial>()
    private let sceneCache = NSCache<NSString, SCNScene>()
    private let maxCacheSize = 50 * 1024 * 1024 // 50MB
    private var cachedOriginalScene: SCNScene?
    // Rendering and UV tuning constants
    private let screenRenderingOrder = 2000
    private let screenUVInset: Float = 0.006
    // Verbose logging toggle (kept false to silence even in Debug)
    private let enableDebugLogging = false
    
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
    
    // Build a contentsTransform for screen textures, centered to avoid clamping artifacts.
    // Compose in this order: translate to center -> rotation -> flips -> translate back.
    // This keeps the UVs within [0,1] and prevents collapsing to a single line.
    private func buildScreenContentsTransform(rotate90: Bool, flipX: Bool, flipY: Bool) -> SCNMatrix4 {
        var m = SCNMatrix4Identity
        // Move pivot to center
        m = SCNMatrix4Translate(m, 0.5, 0.5, 0)
        // Apply rotation about center
        if rotate90 {
            m = SCNMatrix4Rotate(m, .pi / 2, 0, 0, 1)
        }
        // Apply flips about center
        var sx: Float = 1
        var sy: Float = 1
        if flipX { sx = -1 }
        if flipY { sy = -1 }
        m = SCNMatrix4Scale(m, sx, sy, 1)
        // Move pivot back
        m = SCNMatrix4Translate(m, -0.5, -0.5, 0)
        
        // Tiny UV inset to avoid sampling the very edges (prevents horizontal/vertical lines)
        // Shrink slightly around the center, then translate back to keep within [0,1]
        let inset: Float = screenUVInset // ~0.6% inset
        let insetScale: Float = 1 - 2 * inset
        m = SCNMatrix4Translate(m, 0.5, 0.5, 0)
        m = SCNMatrix4Scale(m, insetScale, insetScale, 1)
        m = SCNMatrix4Translate(m, -0.5, -0.5, 0)
        return m
    }
    
    // Choose the UV mapping channel that has the largest V variation to avoid collapsing to a line
    private func chooseBestMappingChannel(for geometry: SCNGeometry) -> Int {
        let texSources = geometry.sources(for: .texcoord)
        guard !texSources.isEmpty else { return 0 }
        var bestIndex = 0
        var bestRange: Float = -1
        for (i, src) in texSources.enumerated() {
            guard src.usesFloatComponents, src.componentsPerVector >= 2 else { continue }
            let stride = src.dataStride
            let offset = src.dataOffset
            let count = src.vectorCount
            let data = src.data
            var minV = Float.greatestFiniteMagnitude
            var maxV: Float = -Float.greatestFiniteMagnitude
            data.withUnsafeBytes { raw in
                guard let base = raw.baseAddress else { return }
                for idx in 0..<count {
                    let ptr = base.advanced(by: offset + idx * stride).assumingMemoryBound(to: Float.self)
                    // U = ptr[0], V = ptr[1]
                    let v = ptr.advanced(by: 1).pointee
                    if v < minV { minV = v }
                    if v > maxV { maxV = v }
                }
            }
            let range = maxV - minV
            if range > bestRange { bestRange = range; bestIndex = i }
        }
        return bestIndex
    }

    // Flip UIImage horizontally to avoid using negative-scale contentsTransform (which can cause striping on some meshes)
    private func flipImageHorizontally(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { ctx in
            let cgctx = ctx.cgContext
            cgctx.translateBy(x: image.size.width, y: 0)
            cgctx.scaleBy(x: -1, y: 1)
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    @objc private func handleMemoryWarning() {
        clearCache()
    }
    
    func applyTextureToModel(_ model: SCNScene, image: UIImage) -> SCNScene? {
        // Optimize the image (resize if necessary)
        let optimizedImage = optimizeImageForTexture(image)
        // Pre-correct horizontal mirroring at the image level
        let correctedImage = flipImageHorizontally(optimizedImage)
        
        // Debug: Output image information
        #if DEBUG
        if enableDebugLogging {
            print("=== Image Debug Info ===")
            print("Original image size: \(image.size)")
            print("Optimized image size: \(optimizedImage.size)")
            print("Image scale: \(optimizedImage.scale)")
            print("========================")
        }
        #endif
        
        // Modify the existing scene directly (do not create a new scene)
        let workingScene = model
        
        #if DEBUG
        if enableDebugLogging {
            print("Using existing scene (no deep copy)")
        }
        #endif
        
        // Debug: Output node structure
        #if DEBUG
        if enableDebugLogging {
            print("=== TextureManager: Scene Node Structure ===")
            debugSceneStructure(workingScene.rootNode, level: 0)
            print("=== End Scene Node Structure ===")
        }
        #endif
        
        // Apply texture only to the screen part of the iPhone model
        var screenFound = false
        var screenNodeCandidates: [(SCNNode, String)] = []
        
        workingScene.rootNode.enumerateChildNodes { (node, stop) in
            // Check node name and geometry existence
            let nodeName = node.name?.lowercased() ?? ""
            let hasGeometry = node.geometry != nil
            
            #if DEBUG
            if enableDebugLogging {
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
            }
            #endif
            
            // Identify the screen node (check for multiple possible names)
            // Added: support for "image_display" and common typo "image_desplay"
            let possibleScreenNames = ["screen", "Screen", "display", "Display", "LCD", "OLED", "Screen_Border", "Ellipse_2_Material", "image_display", "image_desplay"]
            
            let isScreenNode = possibleScreenNames.contains { screenName in
                nodeName.contains(screenName.lowercased())
            }
            
            if isScreenNode && hasGeometry {
                print("✓ Found screen node: '\(node.name ?? "unnamed")'")
                screenNodeCandidates.append((node, node.name ?? "unnamed"))
            } else if isScreenNode && !hasGeometry {
                // Screen name found but no geometry: search descendants for first geometry node
                if let geomNode = findFirstGeometryNode(startingAt: node) {
                    print("✓ Found descendant geometry for screen node '\(node.name ?? "unnamed")' -> '\(geomNode.name ?? "unnamed")'")
                    // Preserve the ORIGINAL screen-node name for candidate selection priority
                    screenNodeCandidates.append((geomNode, node.name ?? geomNode.name ?? "unnamed"))
                } else {
                    print("⚠︎ Screen-named node has no geometry and no descendant geometry: '\(node.name ?? "unnamed")'")
                }
            } else if hasGeometry {
                // Even if it's not a screen name, add nodes with geometry as candidates
                screenNodeCandidates.append((node, node.name ?? "unnamed"))
                #if DEBUG
                if enableDebugLogging {
                    print("Added geometry node as candidate: '\(node.name ?? "unnamed")'")
                }
                #endif
            }
        }
        
        // Select the optimal screen node with improved priority:
        // 1) 'image_display' (or 'display')
        // 2) 'screen' (excluding 'screen_border')
        // 3) 'screen_border'
        // 4) first candidate fallback
        if let screenNode = screenNodeCandidates.first(where: { name in
                                let n = name.1.lowercased()
                                return n.contains("image_display") || (n.contains("display") && !n.contains("border"))
                             }) ??
                           screenNodeCandidates.first(where: { name in
                                let n = name.1.lowercased()
                                return n.contains("screen") && !n.contains("border")
                           }) ??
                           screenNodeCandidates.first(where: { $0.1.lowercased().contains("screen_border") }) ??
                           screenNodeCandidates.first {
            
            #if DEBUG
            print("Applying texture to screen node: '\(screenNode.1)'")
            #endif
            screenFound = true
            
            if let geometry = screenNode.0.geometry {
                #if DEBUG
                print("Screen node has \(geometry.materials.count) materials")
                
                // Debug: Output geometry information
                print("=== Geometry Debug Info ===")
                print("Geometry type: \(type(of: geometry))")
                let sources = geometry.sources
                for source in sources {
                    print("Source semantic: \(source.semantic.rawValue), vectorCount: \(source.vectorCount)")
                }
                print("===========================")
                #endif
                
                // If it is a screen node, it is often a single material, so replace all
                if screenNode.1.lowercased().contains("screen") && geometry.materials.count == 1 {
                    // Create a new material and apply the texture
                    let screenMaterial = SCNMaterial()
                    
                    // Texture quality settings (use emission-only; keep diffuse black to avoid double sampling)
                    screenMaterial.diffuse.contents = UIColor.black
                    screenMaterial.diffuse.wrapS = .clamp
                    screenMaterial.diffuse.wrapT = .clamp
                    screenMaterial.diffuse.minificationFilter = .linear
                    screenMaterial.diffuse.magnificationFilter = .linear
                    screenMaterial.diffuse.mipFilter = .none
                    
                    // Use identity transform (UV inset applied inside builder)
                    let screenTransform1 = buildScreenContentsTransform(rotate90: false, flipX: false, flipY: false)
                    screenMaterial.diffuse.contentsTransform = screenTransform1
                    screenMaterial.emission.contentsTransform = screenTransform1
                    
                    // Render only front face to avoid mirrored artifacts
                    screenMaterial.isDoubleSided = false
                    screenMaterial.cullMode = .back
                    screenMaterial.lightingModel = .constant
                    screenMaterial.emission.contents = correctedImage
                    screenMaterial.emission.wrapS = .clamp
                    screenMaterial.emission.wrapT = .clamp
                    screenMaterial.emission.minificationFilter = .nearest
                    screenMaterial.emission.magnificationFilter = .nearest
                    screenMaterial.emission.mipFilter = .none
                    screenMaterial.emission.intensity = 1.0
                    screenMaterial.blendMode = .replace
                    screenMaterial.readsFromDepthBuffer = false
                    screenMaterial.writesToDepthBuffer = false
                    
                    // Specular reflection settings (kept, though constant lighting minimizes impact)
                    screenMaterial.specular.contents = UIColor.white
                    screenMaterial.shininess = 1.0
                    
                    // Select best UV channel to avoid degenerate V
                    let bestChannel1 = chooseBestMappingChannel(for: geometry)
                    screenMaterial.diffuse.mappingChannel = bestChannel1
                    screenMaterial.emission.mappingChannel = bestChannel1
                    // If it is a single material, replace all
                    geometry.materials = [screenMaterial]
                    // Ensure screen renders on top to avoid Z-fighting
                    screenNode.0.renderingOrder = screenRenderingOrder
                    #if DEBUG
                    print("Applied texture to single material screen node")
                    #endif
                    
                    // Debug: Check material settings
                    #if DEBUG
                    print("=== Material Debug Info ===")
                    print("diffuse.contents: \(screenMaterial.diffuse.contents != nil ? "Set" : "Not Set")")
                    print("emission.contents: \(screenMaterial.emission.contents != nil ? "Set" : "Not Set")")
                    print("diffuse.wrapS: \(screenMaterial.diffuse.wrapS.rawValue)")
                    print("diffuse.wrapT: \(screenMaterial.diffuse.wrapT.rawValue)")
                    if let image = screenMaterial.diffuse.contents as? UIImage {
                        print("Texture image size: \(image.size)")
                    }
                    print("==========================")
                    #endif
                } else {
                    // If there are multiple materials, identify the appropriate index
                    var targetMaterialIndex = -1
                    
                    for (index, material) in geometry.materials.enumerated() {
                        // Infer the screen part from the material name
                        if let materialName = material.name?.lowercased() {
                            if materialName.contains("screen") || materialName.contains("display") || materialName.contains("lcd") {
                                targetMaterialIndex = index
                                #if DEBUG
                                print("Found screen material at index \(index): \(materialName)")
                                #endif
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
                                #if DEBUG
                                print("Found dark material (likely screen) at index \(index): brightness=\(brightness)")
                                #endif
                                break
                            }
                        }
                    }
                    
                    // If a specific material is not found, use the first material
                    if targetMaterialIndex == -1 && !geometry.materials.isEmpty {
                        targetMaterialIndex = 0
                        #if DEBUG
                        print("Using first material as screen (index \(targetMaterialIndex))")
                        #endif
                    }
                    
                    if targetMaterialIndex >= 0 {
                        // Create a new material and apply the texture
                        let screenMaterial = SCNMaterial()
                        
                        // Texture quality settings (use emission-only; keep diffuse black to avoid double sampling)
                        screenMaterial.diffuse.contents = UIColor.black
                        screenMaterial.diffuse.wrapS = .clamp
                        screenMaterial.diffuse.wrapT = .clamp
                        screenMaterial.diffuse.minificationFilter = .linear
                        screenMaterial.diffuse.magnificationFilter = .linear
                        screenMaterial.diffuse.mipFilter = .none
                        
                        // Use identity transform (UV inset applied inside builder)
                        let screenTransform2 = buildScreenContentsTransform(rotate90: false, flipX: false, flipY: false)
                        screenMaterial.diffuse.contentsTransform = screenTransform2
                        screenMaterial.emission.contentsTransform = screenTransform2
                        
                        // Render only front face to avoid mirrored artifacts
                        screenMaterial.isDoubleSided = false
                        screenMaterial.cullMode = .back
                        screenMaterial.lightingModel = .constant
                        screenMaterial.emission.contents = correctedImage
                        screenMaterial.emission.wrapS = .clamp
                        screenMaterial.emission.wrapT = .clamp
                        screenMaterial.emission.minificationFilter = .nearest
                        screenMaterial.emission.magnificationFilter = .nearest
                        screenMaterial.emission.mipFilter = .none
                        screenMaterial.emission.intensity = 1.0
                        screenMaterial.blendMode = .replace
                        screenMaterial.readsFromDepthBuffer = false
                        screenMaterial.writesToDepthBuffer = false
                        
                        // Specular reflection settings (kept, though constant lighting minimizes impact)
                        screenMaterial.specular.contents = UIColor.white
                        screenMaterial.shininess = 1.0
                        
                        // Select best UV channel to avoid degenerate V
                        let bestChannel2 = chooseBestMappingChannel(for: geometry)
                        screenMaterial.diffuse.mappingChannel = bestChannel2
                        screenMaterial.emission.mappingChannel = bestChannel2
                        // Replace only the specific material index
                        geometry.materials[targetMaterialIndex] = screenMaterial
                        // Ensure screen renders on top to avoid Z-fighting
                        screenNode.0.renderingOrder = screenRenderingOrder
                        #if DEBUG
                        print("Applied texture to material index \(targetMaterialIndex)")
                        #endif
                    }
                }
            }
        } else if !screenNodeCandidates.isEmpty {
            // If no screen candidates are found, identify the screen part based on the material
            let node = screenNodeCandidates.first!.0
            if let geometry = node.geometry {
                #if DEBUG
                print("Attempting material-based screen detection on '\(node.name ?? "unnamed")' with \(geometry.materials.count) materials")
                #endif
                
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
                    #if DEBUG
                    print("Using last material as screen (index \(targetMaterialIndex))")
                    #endif
                }
                
                if targetMaterialIndex >= 0 {
                    // Create a new material and apply the texture
                    let screenMaterial = SCNMaterial()
                    
                    // Texture quality settings (use emission-only; keep diffuse black)
                    screenMaterial.diffuse.contents = UIColor.black
                    screenMaterial.diffuse.wrapS = .clamp
                    screenMaterial.diffuse.wrapT = .clamp
                    screenMaterial.diffuse.minificationFilter = .linear
                    screenMaterial.diffuse.magnificationFilter = .linear
                    screenMaterial.diffuse.mipFilter = .none
                    
                    // Use identity transform (UV inset applied inside builder)
                    let screenTransform3 = buildScreenContentsTransform(rotate90: false, flipX: false, flipY: false)
                    screenMaterial.diffuse.contentsTransform = screenTransform3
                    screenMaterial.emission.contentsTransform = screenTransform3
                    
                    // Render only front face to avoid mirrored artifacts
                    screenMaterial.isDoubleSided = false
                    screenMaterial.cullMode = .back
                    screenMaterial.lightingModel = .constant
                    screenMaterial.emission.contents = correctedImage
                    screenMaterial.emission.wrapS = .clamp
                    screenMaterial.emission.wrapT = .clamp
                    screenMaterial.emission.minificationFilter = .nearest
                    screenMaterial.emission.magnificationFilter = .nearest
                    screenMaterial.emission.mipFilter = .none
                    screenMaterial.emission.intensity = 1.0
                    screenMaterial.blendMode = .replace
                    screenMaterial.readsFromDepthBuffer = false
                    screenMaterial.writesToDepthBuffer = false
                    
                    // Specular reflection settings (kept, though constant lighting minimizes impact)
                    screenMaterial.specular.contents = UIColor.white
                    screenMaterial.shininess = 1.0
                    
                    // Select best UV channel to avoid degenerate V
                    let bestChannel3 = chooseBestMappingChannel(for: geometry)
                    screenMaterial.diffuse.mappingChannel = bestChannel3
                    screenMaterial.emission.mappingChannel = bestChannel3
                    // Replace only the specific material index
                    geometry.materials[targetMaterialIndex] = screenMaterial
                    // Ensure screen renders on top to avoid Z-fighting
                    node.renderingOrder = screenRenderingOrder
                    screenFound = true
                    #if DEBUG
                    print("Applied texture to material index \(targetMaterialIndex)")
                    #endif
                }
            }
        }
        
        // Alternative processing if no screen node is found
        if !screenFound {
            var geometryNodes: [(SCNNode, String)] = []
            #if DEBUG
            print("⚠️ Warning: No screen node found with geometry from candidates: \(screenNodeCandidates.map { $0.1 })")
            print("Available nodes with geometry:")
            #endif
            workingScene.rootNode.enumerateChildNodes { (node, _) in
                if let geometry = node.geometry {
                    let nodeName = node.name ?? "unnamed"
                    geometryNodes.append((node, nodeName))
                    #if DEBUG
                    print("  - \(nodeName) (materials: \(geometry.materials.count))")
                    #endif
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
                #if DEBUG
                print("Applying texture to largest geometry node: '\(largestNode.1)' with \(largestNode.0.geometry?.materials.count ?? 0) materials")
                #endif
                
                if let geometry = largestNode.0.geometry {
                    // Identify the appropriate material index even for the largest node
                    var targetMaterialIndex = -1
                    
                    for (index, material) in geometry.materials.enumerated() {
                        // Infer the screen part from the material name
                        if let materialName = material.name?.lowercased() {
                            if materialName.contains("screen") || materialName.contains("display") || materialName.contains("lcd") {
                                targetMaterialIndex = index
                                #if DEBUG
                                print("Found screen material at index \(index): \(materialName)")
                                #endif
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
                                #if DEBUG
                                print("Found dark material (likely screen) at index \(index): brightness=\(brightness)")
                                #endif
                                break
                            }
                        }
                    }
                    
                    // If a specific material is not found, use the last material (usually the screen part)
                    if targetMaterialIndex == -1 && !geometry.materials.isEmpty {
                        targetMaterialIndex = geometry.materials.count - 1
                        #if DEBUG
                        print("Using last material as screen (index \(targetMaterialIndex))")
                        #endif
                    }
                    
                    if targetMaterialIndex >= 0 {
                        let screenMaterial = SCNMaterial()
                        screenMaterial.diffuse.contents = UIColor.black
                        screenMaterial.diffuse.wrapS = .clamp
                        screenMaterial.diffuse.wrapT = .clamp
                        screenMaterial.diffuse.minificationFilter = .linear
                        screenMaterial.diffuse.magnificationFilter = .linear
                        screenMaterial.diffuse.mipFilter = .none
                        // Use identity transform (UV inset applied inside builder)
                        let screenTransform4 = buildScreenContentsTransform(rotate90: false, flipX: false, flipY: false)
                        screenMaterial.diffuse.contentsTransform = screenTransform4
                        screenMaterial.emission.contentsTransform = screenTransform4
                        // Render only front face to avoid mirrored artifacts
                        screenMaterial.isDoubleSided = false
                        screenMaterial.cullMode = .back
                        screenMaterial.lightingModel = .constant
                        screenMaterial.emission.contents = correctedImage
                        screenMaterial.emission.wrapS = .clamp
                        screenMaterial.emission.wrapT = .clamp
                        screenMaterial.emission.minificationFilter = .nearest
                        screenMaterial.emission.magnificationFilter = .nearest
                        screenMaterial.emission.mipFilter = .none
                        screenMaterial.emission.intensity = 1.0
                        screenMaterial.blendMode = .replace
                        screenMaterial.readsFromDepthBuffer = false
                        screenMaterial.writesToDepthBuffer = false
                        screenMaterial.specular.contents = UIColor.white
                        screenMaterial.shininess = 1.0
                        
                        // Replace only the specific material index
                        geometry.materials[targetMaterialIndex] = screenMaterial
                        // Ensure screen renders on top to avoid Z-fighting
                        largestNode.0.renderingOrder = screenRenderingOrder
                        screenFound = true
                        #if DEBUG
                        print("Applied texture to material index \(targetMaterialIndex) of largest node")
                        #endif
                    }
                }
            }
        }
        
        // Error if screen node is not found
        guard screenFound else {
            print("Warning: Screen node not found in model")
            return nil
        }
        
        #if DEBUG
        print("Successfully applied texture to existing scene")
        #endif
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
            
            // Find screen node candidates
            // Added: support for "image_display" and common typo "image_desplay"
            let possibleScreenNames = ["screen", "Screen", "display", "Display", "LCD", "OLED", "Screen_Border", "Ellipse_2_Material", "image_display", "image_desplay"]
            let isScreenNode = possibleScreenNames.contains { screenName in
                nodeName.contains(screenName.lowercased())
            }
            
            if hasGeometry, let geometry = node.geometry {
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
            } else if isScreenNode && !hasGeometry {
                // Screen-named node without geometry: try clearing first descendant geometry
                if let geomNode = findFirstGeometryNode(startingAt: node), let geometry = geomNode.geometry {
                    print("Clearing texture from descendant geometry node: '\(geomNode.name ?? "unnamed")' for screen '\(node.name ?? "unnamed")'")
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
        // Optimize the texture size (max 2048x2048)
        let maxSize: CGFloat = 2048
        let currentSize = image.size
        
        if currentSize.width <= maxSize && currentSize.height <= maxSize {
            return image
        }
        
        let scale = min(maxSize / currentSize.width, maxSize / currentSize.height)
        let newSize = CGSize(width: currentSize.width * scale, height: currentSize.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let optimizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
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
    
    // Find the first descendant node (including the starting node) that has a geometry
    private func findFirstGeometryNode(startingAt node: SCNNode) -> SCNNode? {
        if node.geometry != nil { return node }
        var stack: [SCNNode] = node.childNodes
        while !stack.isEmpty {
            let current = stack.removeFirst()
            if current.geometry != nil { return current }
            stack.append(contentsOf: current.childNodes)
        }
        return nil
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
