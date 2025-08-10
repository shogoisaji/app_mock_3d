import SceneKit
import Foundation

// 3Dモデルを一元管理する列挙型
enum ModelAsset: String, CaseIterable {
    case iphone16    // "iphone16.usdc"
    case iphoneSE    // "iphoneSE.usdc"

    // リソース探索用のベース名（拡張子なし）
    var resourceName: String {
        switch self {
        case .iphone16: return "iphone16"
        case .iphoneSE: return "iphoneSE"
        }
    }

    // UI表示などに使える表示名
    var displayName: String {
        switch self {
        case .iphone16: return "A"
        case .iphoneSE: return "B"
        }
    }
}

class ModelManager {
    static let shared = ModelManager()
    
    private init() {}
    
    // 新API: 一元管理された ModelAsset からロード
    func loadModel(_ asset: ModelAsset) -> SCNScene? {
        // 名称の大文字小文字違いにロバストに対応
        let base = asset.resourceName
        var candidates: [String] = [base]
        if asset == .iphoneSE {
            // いくつかのバリエーションも探索
            candidates.append(contentsOf: ["iphoneSe", "iphonese", "IphoneSE", "IphoneSe"]) 
        }
        for name in candidates {
            if let scene = loadModel(named: name) {
                return scene
            }
        }
        return loadModel(named: base)
    }
    
    func loadModel(named modelName: String) -> SCNScene? {
        // Attempt to locate a model file using ModelFileLocator.
        if let url = ModelFileLocator.locateModel(named: modelName) {
            if let scene = ModelFileLocator.loadScene(from: url) {
                return scene
            }
        }
        
        // If no model is found, fall back to a placeholder model.
        #if DEBUG
        print("Using placeholder model for: \(modelName)")
        #endif
        return createPlaceholderModel()
    }
    
    private func load3DModel(named modelName: String) -> SCNScene? {
        // Use ModelFileLocator to locate and load the model.
        if let url = ModelFileLocator.locateModel(named: modelName) {
            return ModelFileLocator.loadScene(from: url)
        }
        #if DEBUG
        print("No supported 3D model found for: \(modelName)")
        #endif
        return nil
    }
    
    private func loadSceneFromURL(_ url: URL, modelName: String) -> SCNScene? {
        do {
            #if DEBUG
            print("Loading 3D model from: \(url.path)")
            #endif
            
            // SceneSourceを使用してより詳細な情報を取得
            let sceneSource = SCNSceneSource(url: url, options: nil)
            
            // 利用可能な識別子をログ出力
            #if DEBUG
            if let identifiers = sceneSource?.identifiersOfEntries(withClass: SCNGeometry.self) {
                print("Available geometry identifiers: \(identifiers)")
            }
            if let nodeIdentifiers = sceneSource?.identifiersOfEntries(withClass: SCNNode.self) {
                print("Available node identifiers: \(nodeIdentifiers)")
            }
            #endif
            
            let scene = try SCNScene(url: url, options: [
                SCNSceneSource.LoadingOption.convertToYUp: true,
                SCNSceneSource.LoadingOption.convertUnitsToMeters: false,
                SCNSceneSource.LoadingOption.preserveOriginalTopology: true,
                SCNSceneSource.LoadingOption.strictConformance: false,
                SCNSceneSource.LoadingOption.createNormalsIfAbsent: true,
                SCNSceneSource.LoadingOption.checkConsistency: false
            ])
            
            // Apply default materials to the loaded model
            setupDefaultMaterials(for: scene)
            
            #if DEBUG
            print("Successfully loaded 3D model: \(modelName) from \(url.pathExtension.uppercased())")
            #endif
            return scene
        } catch {
            #if DEBUG
            print("Failed to load 3D model from \(url.path): \(error)")
            #endif
            return nil
        }
    }
    
    private func applyPostLoadAdjustments(for asset: ModelAsset, scene: SCNScene) {
        // 材質セットアップ（loadSceneFromURL 内でも実施済みだが二重適用は安全）
        setupDefaultMaterials(for: scene)
    }
    
    private func setupDefaultMaterials(for scene: SCNScene) {
        #if DEBUG
        print("=== Model Node Structure Debug ===")
        debugNodeStructure(scene.rootNode, level: 0)
        print("=== End Model Node Structure Debug ===")
        #endif
        
        scene.rootNode.enumerateChildNodes { (node, _) in
            if let geometry = node.geometry {
                // 材質が設定されていない場合、デフォルト材質を適用
                if geometry.materials.isEmpty {
                    geometry.materials = [createDefaultMaterial()]
                } else {
                    // 既存の材質を改良
                    for i in 0..<geometry.materials.count {
                        let material = geometry.materials[i]
                        
                        // 材質の内容が設定されていない場合
                        if material.diffuse.contents == nil {
                            let nodeNameLower = (node.name ?? "").lowercased()
                            if nodeNameLower == "screen" || nodeNameLower == "image_display" {
                                // 画面ノードには黒い材質
                                material.diffuse.contents = UIColor.black
                                material.specular.contents = UIColor.white
                                material.shininess = 1.0
                                // 表裏の違いで消えることを防ぐ
                                material.isDoubleSided = true
                                material.cullMode = .back
                                // 透明化を明示的に無効化
                                material.transparency = 1.0
                                material.transparent.contents = nil
                                material.transparencyMode = .aOne
                            } else {
                                // その他の部分にはグレーの材質
                                material.diffuse.contents = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
                                material.specular.contents = UIColor.white
                                material.shininess = 0.6
                            }
                        } else {
                            // 既に材質がある場合でも、画面系ノードは裏面カリングで消えないように最低限の設定を入れる
                            let nodeNameLower = (node.name ?? "").lowercased()
                            if nodeNameLower == "screen" || nodeNameLower == "image_display" {
                                material.isDoubleSided = true
                                material.cullMode = .back
                                material.transparency = 1.0
                                material.transparent.contents = nil
                                material.transparencyMode = .aOne
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func debugNodeStructure(_ node: SCNNode, level: Int) {
        let indent = String(repeating: "  ", count: level)
        let nodeName = node.name ?? "unnamed"
        let hasGeometry = node.geometry != nil
        let materialCount = node.geometry?.materials.count ?? 0
        
        #if DEBUG
        print("\(indent)- \(nodeName) (geometry: \(hasGeometry), materials: \(materialCount))")
        #endif
        
        for child in node.childNodes {
            debugNodeStructure(child, level: level + 1)
        }
    }
    
    private func createDefaultMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        material.specular.contents = UIColor.white
        material.shininess = 0.5
        return material
    }
    
    private func createPlaceholderModel() -> SCNScene? {
        let scene = SCNScene()
        
        // Create iPhone body
        let phoneBody = SCNBox(width: 0.8, height: 1.6, length: 0.08, chamferRadius: 0.08)
        let bodyMaterial = SCNMaterial()
        bodyMaterial.diffuse.contents = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0) // Dark gray
        bodyMaterial.specular.contents = UIColor.white
        bodyMaterial.shininess = 0.8
        phoneBody.materials = [bodyMaterial]
        
        let phoneBodyNode = SCNNode(geometry: phoneBody)
        phoneBodyNode.name = "iphone1"
        scene.rootNode.addChildNode(phoneBodyNode)
        
        // Create screen (this is where images will be applied)
        let screen = SCNBox(width: 0.65, height: 1.35, length: 0.001, chamferRadius: 0.02)
        let screenMaterial = SCNMaterial()
        screenMaterial.diffuse.contents = UIColor.black // Default is a black screen
        screenMaterial.specular.contents = UIColor.white
        screenMaterial.shininess = 1.0
        // デフォルトでも表裏の違いで消えないようにする
        screenMaterial.isDoubleSided = true
        screenMaterial.cullMode = .back
        screenMaterial.transparency = 1.0
        screenMaterial.transparent.contents = nil
        screenMaterial.transparencyMode = .aOne
        screen.materials = [screenMaterial]
        
        let screenNode = SCNNode(geometry: screen)
        screenNode.name = "screen" // Ensure the screen name is set
        screenNode.position = SCNVector3(x: 0, y: 0, z: 0.041) // Position in front of the body
        phoneBodyNode.addChildNode(screenNode)
        
        #if DEBUG
        print("Created placeholder model with screen node: \(screenNode.name ?? "unnamed")")
        #endif
        
        // Create home button area (for visual detail)
        let homeButtonArea = SCNBox(width: 0.6, height: 0.15, length: 0.001, chamferRadius: 0.01)
        let homeButtonMaterial = SCNMaterial()
        homeButtonMaterial.diffuse.contents = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        homeButtonArea.materials = [homeButtonMaterial]
        
        let homeButtonNode = SCNNode(geometry: homeButtonArea)
        homeButtonNode.position = SCNVector3(x: 0, y: -0.75, z: 0.041)
        phoneBodyNode.addChildNode(homeButtonNode)
        
        // Position the entire phone model appropriately
        phoneBodyNode.position = SCNVector3(x: 0, y: 0, z: 0)
        
        return scene
    }
}
 
