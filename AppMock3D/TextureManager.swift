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
        sceneCache.countLimit = 10 // シーンの数を制限
        
        // メモリ警告の監視
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
        // 画像を最適化（必要に応じてリサイズ）
        let optimizedImage = optimizeImageForTexture(image)
        
        // デバッグ: 画像情報を出力
        print("=== Image Debug Info ===")
        print("Original image size: \(image.size)")
        print("Optimized image size: \(optimizedImage.size)")
        print("Image scale: \(optimizedImage.scale)")
        print("========================")
        
        // 既存のシーンを直接修正する（新しいシーンを作らない）
        let workingScene = model
        
        print("Using existing scene (no deep copy)")
        
        // デバッグ: ノード構造を出力
        print("=== TextureManager: Scene Node Structure ===")
        debugSceneStructure(workingScene.rootNode, level: 0)
        print("=== End Scene Node Structure ===")
        
        // iPhoneモデルの画面部分のみにテクスチャを適用
        var screenFound = false
        var screenNodeCandidates: [(SCNNode, String)] = []
        
        workingScene.rootNode.enumerateChildNodes { (node, stop) in
            // ノード名とジオメトリの存在をチェック
            let nodeName = node.name?.lowercased() ?? ""
            let hasGeometry = node.geometry != nil
            
            print("Checking node: '\(node.name ?? "unnamed")' (has geometry: \(hasGeometry))")
            
            // ジオメトリがある場合、その詳細も出力
            if hasGeometry, let geometry = node.geometry {
                print("  └─ Geometry type: \(type(of: geometry))")
                print("  └─ Materials count: \(geometry.materials.count)")
                if !geometry.materials.isEmpty {
                    for (index, material) in geometry.materials.enumerated() {
                        print("    └─ Material \(index): \(material.name ?? "unnamed")")
                    }
                }
            }
            
            // 画面ノードを特定（複数の可能性のある名前をチェック）
            let possibleScreenNames = ["screen", "Screen", "display", "Display", "LCD", "OLED", "Screen_Border", "Ellipse_2_Material"]
            
            let isScreenNode = possibleScreenNames.contains { screenName in
                nodeName.contains(screenName.lowercased())
            }
            
            if isScreenNode && hasGeometry {
                print("✓ Found screen node: '\(node.name ?? "unnamed")'")
                screenNodeCandidates.append((node, node.name ?? "unnamed"))
            } else if hasGeometry {
                // スクリーン名でなくても、ジオメトリを持つノードは候補として追加
                screenNodeCandidates.append((node, node.name ?? "unnamed"))
                print("Added geometry node as candidate: '\(node.name ?? "unnamed")'")
            }
        }
        
        // 最適な画面ノードを選択（"screen"が最優先、次に"Screen_Border"）
        if let screenNode = screenNodeCandidates.first(where: { $0.1.lowercased().contains("screen") && !$0.1.lowercased().contains("border") }) ??
                           screenNodeCandidates.first(where: { $0.1.lowercased().contains("screen_border") }) ??
                           screenNodeCandidates.first {
            
            print("Applying texture to screen node: '\(screenNode.1)'")
            screenFound = true
            
            if let geometry = screenNode.0.geometry {
                print("Screen node has \(geometry.materials.count) materials")
                
                // デバッグ: ジオメトリ情報の出力
                print("=== Geometry Debug Info ===")
                print("Geometry type: \(type(of: geometry))")
                let sources = geometry.sources
                for source in sources {
                    print("Source semantic: \(source.semantic.rawValue), vectorCount: \(source.vectorCount)")
                }
                print("===========================")
                
                // screenノードの場合、単一マテリアルであることが多いので全て置き換え
                if screenNode.1.lowercased().contains("screen") && geometry.materials.count == 1 {
                    // 新しいマテリアルを作成してテクスチャを適用
                    let screenMaterial = SCNMaterial()
                    
                    // テクスチャの品質設定
                    screenMaterial.diffuse.contents = optimizedImage
                    screenMaterial.diffuse.wrapS = .clamp
                    screenMaterial.diffuse.wrapT = .clamp
                    screenMaterial.diffuse.minificationFilter = .linear
                    screenMaterial.diffuse.magnificationFilter = .linear
                    
                    // UV座標の正確な適用（画像は既に事前反転済み）
                    // 水平反転を修正するためにcontentsTransformを調整
                    let transform = SCNMatrix4MakeScale(-1, 1, 1)
                    screenMaterial.diffuse.contentsTransform = SCNMatrix4Translate(transform, 1, 0, 0)
                    
                    // 画面の発光効果を追加（リアルな表示のため）
                    // 一時的に発光効果を無効化してテスト
                    // screenMaterial.emission.contents = optimizedImage
                    // screenMaterial.emission.intensity = 0.1
                    
                    // スペキュラ反射の設定
                    screenMaterial.specular.contents = UIColor.white
                    screenMaterial.shininess = 1.0
                    
                    // 単一マテリアルの場合は全て置き換え
                    geometry.materials = [screenMaterial]
                    print("Applied texture to single material screen node")
                    
                    // デバッグ: マテリアル設定の確認
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
                    // 複数マテリアルの場合は適切なインデックスを特定
                    var targetMaterialIndex = -1
                    
                    for (index, material) in geometry.materials.enumerated() {
                        // マテリアルの名前から画面部分を推測
                        if let materialName = material.name?.lowercased() {
                            if materialName.contains("screen") || materialName.contains("display") || materialName.contains("lcd") {
                                targetMaterialIndex = index
                                print("Found screen material at index \(index): \(materialName)")
                                break
                            }
                        }
                        
                        // 色による判定（黒っぽい色を画面として推測）
                        if let diffuseColor = material.diffuse.contents as? UIColor {
                            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                            diffuseColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                            let brightness = (red + green + blue) / 3.0
                            
                            if brightness < 0.3 { // 暗い色（おそらく画面）
                                targetMaterialIndex = index
                                print("Found dark material (likely screen) at index \(index): brightness=\(brightness)")
                                break
                            }
                        }
                    }
                    
                    // 特定のマテリアルが見つからない場合、最初のマテリアルを使用
                    if targetMaterialIndex == -1 && !geometry.materials.isEmpty {
                        targetMaterialIndex = 0
                        print("Using first material as screen (index \(targetMaterialIndex))")
                    }
                    
                    if targetMaterialIndex >= 0 {
                        // 新しいマテリアルを作成してテクスチャを適用
                        let screenMaterial = SCNMaterial()
                        
                        // テクスチャの品質設定
                        screenMaterial.diffuse.contents = optimizedImage
                        screenMaterial.diffuse.wrapS = .clamp
                        screenMaterial.diffuse.wrapT = .clamp
                        screenMaterial.diffuse.minificationFilter = .linear
                        screenMaterial.diffuse.magnificationFilter = .linear
                        
                        // UV座標の正確な適用（画像は既に事前反転済み）
                        // 水平反転を修正するためにcontentsTransformを調整
                        let transform = SCNMatrix4MakeScale(-1, 1, 1)
                        screenMaterial.diffuse.contentsTransform = SCNMatrix4Translate(transform, 1, 0, 0)
                        
                        // 画面の発光効果を追加（リアルな表示のため）
                        // 一時的に発光効果を無効化してテスト
                        // screenMaterial.emission.contents = optimizedImage
                        // screenMaterial.emission.intensity = 0.1
                        
                        // スペキュラ反射の設定
                        screenMaterial.specular.contents = UIColor.white
                        screenMaterial.shininess = 1.0
                        
                        // 特定のマテリアルインデックスのみを置き換え
                        geometry.materials[targetMaterialIndex] = screenMaterial
                        print("Applied texture to material index \(targetMaterialIndex)")
                    }
                }
            }
        } else if !screenNodeCandidates.isEmpty {
            // スクリーン候補が見つからない場合、マテリアルベースで画面部分を特定
            let node = screenNodeCandidates.first!.0
            if let geometry = node.geometry {
                print("Attempting material-based screen detection on '\(node.name ?? "unnamed")' with \(geometry.materials.count) materials")
                
                // 画面に適したマテリアルを探す（通常は黒や暗い色、または名前に"screen"を含む）
                var targetMaterialIndex = -1
                
                for (index, material) in geometry.materials.enumerated() {
                    // マテリアルの色や名前から画面部分を推測
                    if let materialName = material.name?.lowercased() {
                        if materialName.contains("screen") || materialName.contains("display") || materialName.contains("lcd") {
                            targetMaterialIndex = index
                            print("Found screen material at index \(index): \(materialName)")
                            break
                        }
                    }
                    
                    // 色による判定（黒っぽい色を画面として推測）
                    if let diffuseColor = material.diffuse.contents as? UIColor {
                        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                        diffuseColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                        let brightness = (red + green + blue) / 3.0
                        
                        if brightness < 0.3 { // 暗い色（おそらく画面）
                            targetMaterialIndex = index
                            print("Found dark material (likely screen) at index \(index): brightness=\(brightness)")
                            break
                        }
                    }
                }
                
                // 特定のマテリアルが見つからない場合、最後のマテリアル（通常画面部分）を使用
                if targetMaterialIndex == -1 && !geometry.materials.isEmpty {
                    targetMaterialIndex = geometry.materials.count - 1
                    print("Using last material as screen (index \(targetMaterialIndex))")
                }
                
                if targetMaterialIndex >= 0 {
                    // 新しいマテリアルを作成してテクスチャを適用
                    let screenMaterial = SCNMaterial()
                    
                    // テクスチャの品質設定
                    screenMaterial.diffuse.contents = optimizedImage
                    screenMaterial.diffuse.wrapS = .clamp
                    screenMaterial.diffuse.wrapT = .clamp
                    screenMaterial.diffuse.minificationFilter = .linear
                    screenMaterial.diffuse.magnificationFilter = .linear
                    
                    // UV座標の正確な適用
                    // 水平反転を修正するためにcontentsTransformを調整
                    let transform = SCNMatrix4MakeScale(-1, 1, 1)
                    screenMaterial.diffuse.contentsTransform = SCNMatrix4Translate(transform, 1, 0, 0)
                    
                    // 画面の発光効果を追加（リアルな表示のため）
                    // 一時的に発光効果を無効化してテスト
                    // screenMaterial.emission.contents = optimizedImage
                    // screenMaterial.emission.intensity = 0.1
                    
                    // スペキュラ反射の設定
                    screenMaterial.specular.contents = UIColor.white
                    screenMaterial.shininess = 1.0
                    
                    // 特定のマテリアルインデックスのみを置き換え
                    geometry.materials[targetMaterialIndex] = screenMaterial
                    screenFound = true
                    
                    print("Applied texture to material index \(targetMaterialIndex)")
                }
            }
        }
        
        // 画面ノードが見つからない場合の代替処理
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
            
            // より大きなジオメトリ（おそらく画面）を探す
            if let largestNode = geometryNodes.max(by: { (node1, node2) in
                let bounds1 = node1.0.boundingBox
                let bounds2 = node2.0.boundingBox
                let volume1 = (bounds1.max.x - bounds1.min.x) * (bounds1.max.y - bounds1.min.y) * (bounds1.max.z - bounds1.min.z)
                let volume2 = (bounds2.max.x - bounds2.min.x) * (bounds2.max.y - bounds2.min.y) * (bounds2.max.z - bounds2.min.z)
                return volume1 < volume2
            }) {
                print("Applying texture to largest geometry node: '\(largestNode.1)' with \(largestNode.0.geometry?.materials.count ?? 0) materials")
                
                if let geometry = largestNode.0.geometry {
                    // 最大ノードでも適切なマテリアルインデックスを特定
                    var targetMaterialIndex = -1
                    
                    for (index, material) in geometry.materials.enumerated() {
                        // マテリアルの名前から画面部分を推測
                        if let materialName = material.name?.lowercased() {
                            if materialName.contains("screen") || materialName.contains("display") || materialName.contains("lcd") {
                                targetMaterialIndex = index
                                print("Found screen material at index \(index): \(materialName)")
                                break
                            }
                        }
                        
                        // 色による判定（黒っぽい色を画面として推測）
                        if let diffuseColor = material.diffuse.contents as? UIColor {
                            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                            diffuseColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                            let brightness = (red + green + blue) / 3.0
                            
                            if brightness < 0.3 { // 暗い色（おそらく画面）
                                targetMaterialIndex = index
                                print("Found dark material (likely screen) at index \(index): brightness=\(brightness)")
                                break
                            }
                        }
                    }
                    
                    // 特定のマテリアルが見つからない場合、最後のマテリアル（通常画面部分）を使用
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
                        // 水平反転を修正するためにcontentsTransformを調整
                        let transform = SCNMatrix4MakeScale(-1, 1, 1)
                        screenMaterial.diffuse.contentsTransform = SCNMatrix4Translate(transform, 1, 0, 0)
                        // 一時的に発光効果を無効化してテスト
                        // screenMaterial.emission.contents = optimizedImage
                        // screenMaterial.emission.intensity = 0.05
                        screenMaterial.specular.contents = UIColor.white
                        screenMaterial.shininess = 1.0
                        
                        // 特定のマテリアルインデックスのみを置き換え
                        geometry.materials[targetMaterialIndex] = screenMaterial
                        screenFound = true
                        print("Applied texture to material index \(targetMaterialIndex) of largest node")
                    }
                }
            }
        }
        
        // 画面ノードが見つからない場合はエラー
        guard screenFound else {
            print("Warning: Screen node not found in model")
            return nil
        }
        
        print("Successfully applied texture to existing scene")
        return workingScene
    }
    
    // 画像テクスチャをクリアして元の状態に戻す
    func clearTextureFromModel(_ model: SCNScene) -> SCNScene? {
        print("Clearing texture from existing scene")
        
        // iPhoneモデルの画面部分を見つけて元の黒い画面に戻す
        var screenFound = false
        
        model.rootNode.enumerateChildNodes { (node, stop) in
            let nodeName = node.name?.lowercased() ?? ""
            let hasGeometry = node.geometry != nil
            
            if hasGeometry, let geometry = node.geometry {
                // 画面ノード候補を探す
                let possibleScreenNames = ["screen", "Screen", "display", "Display", "LCD", "OLED", "Screen_Border", "Ellipse_2_Material"]
                let isScreenNode = possibleScreenNames.contains { screenName in
                    nodeName.contains(screenName.lowercased())
                }
                
                if isScreenNode || (!screenFound && hasGeometry) {
                    print("Clearing texture from node: '\(node.name ?? "unnamed")'")
                    
                    // 画面マテリアルを元の黒い画面に戻す
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
        // まず画像を上下反転
        let flippedImage = flipImageVertically(image)
        
        // テクスチャサイズを最適化（最大2048x2048）
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
        
        // 座標系を上下反転
        context.translateBy(x: 0, y: image.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        // 画像を描画
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
        // デバッグ用のキャッシュ情報取得
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
