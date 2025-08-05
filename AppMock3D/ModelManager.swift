import SceneKit
import Foundation

class ModelManager {
    static let shared = ModelManager()
    
    private init() {}
    
    func loadModel(named modelName: String) -> SCNScene? {
        print("Attempting to load model: \(modelName)")
        
        // Debug: List all resources in bundle
        if let resourcePath = Bundle.main.resourcePath {
            let resourceURL = URL(fileURLWithPath: resourcePath)
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil)
                let objFiles = contents.filter { $0.pathExtension == "obj" }
                print("Available OBJ files in bundle: \(objFiles.map { $0.lastPathComponent })")
            } catch {
                print("Error listing bundle contents: \(error)")
            }
        }
        
        // First try to load a 3D model file from the bundle
        if let scene = load3DModel(named: modelName) {
            return scene
        }
        
        print("Using placeholder model for: \(modelName)")
        // If no OBJ file is found, create a placeholder model
        return createPlaceholderModel()
    }
    
    private func load3DModel(named modelName: String) -> SCNScene? {
        // 推奨順序で3Dファイル形式を試行 (USDC > USDZ > DAE > SCN > OBJ)
        let extensions = ["usdc", "usdz", "dae", "scn", "obj"]
        
        for ext in extensions {
            // まずメインバンドルから検索
            if let url = Bundle.main.url(forResource: modelName, withExtension: ext) {
                print("Found \(ext.uppercased()) file in bundle: \(modelName).\(ext)")
                return loadSceneFromURL(url, modelName: modelName)
            }
            
            // Assetsディレクトリからも検索
            if let url = Bundle.main.url(forResource: "Assets/\(modelName)", withExtension: ext) {
                print("Found \(ext.uppercased()) file in Assets: \(modelName).\(ext)")
                return loadSceneFromURL(url, modelName: modelName)
            }
        }
        
        print("No supported 3D model found for: \(modelName)")
        return nil
    }
    
    private func loadSceneFromURL(_ url: URL, modelName: String) -> SCNScene? {
        do {
            print("Loading 3D model from: \(url.path)")
            
            // SceneSourceを使用してより詳細な情報を取得
            let sceneSource = SCNSceneSource(url: url, options: nil)
            
            // 利用可能な識別子をログ出力
            if let identifiers = sceneSource?.identifiersOfEntries(withClass: SCNGeometry.self) {
                print("Available geometry identifiers: \(identifiers)")
            }
            if let nodeIdentifiers = sceneSource?.identifiersOfEntries(withClass: SCNNode.self) {
                print("Available node identifiers: \(nodeIdentifiers)")
            }
            
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
            
            print("Successfully loaded 3D model: \(modelName) from \(url.pathExtension.uppercased())")
            return scene
        } catch {
            print("Failed to load 3D model from \(url.path): \(error)")
            return nil
        }
    }
    
    private func setupDefaultMaterials(for scene: SCNScene) {
        print("=== Model Node Structure Debug ===")
        debugNodeStructure(scene.rootNode, level: 0)
        print("=== End Node Structure Debug ===")
        
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
                            if node.name == "screen" {
                                // 画面ノードには黒い材質
                                material.diffuse.contents = UIColor.black
                                material.specular.contents = UIColor.white
                                material.shininess = 1.0
                            } else {
                                // その他の部分にはグレーの材質
                                material.diffuse.contents = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
                                material.specular.contents = UIColor.white
                                material.shininess = 0.6
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
        
        print("\(indent)- \(nodeName) (geometry: \(hasGeometry), materials: \(materialCount))")
        
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
        bodyMaterial.diffuse.contents = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0) // ダークグレー
        bodyMaterial.specular.contents = UIColor.white
        bodyMaterial.shininess = 0.8
        phoneBody.materials = [bodyMaterial]
        
        let phoneBodyNode = SCNNode(geometry: phoneBody)
        phoneBodyNode.name = "iPhone"
        scene.rootNode.addChildNode(phoneBodyNode)
        
        // Create screen (this is where images will be applied)
        let screen = SCNBox(width: 0.65, height: 1.35, length: 0.001, chamferRadius: 0.02)
        let screenMaterial = SCNMaterial()
        screenMaterial.diffuse.contents = UIColor.black // デフォルトは黒い画面
        screenMaterial.specular.contents = UIColor.white
        screenMaterial.shininess = 1.0
        screen.materials = [screenMaterial]
        
        let screenNode = SCNNode(geometry: screen)
        screenNode.name = "screen" // 確実にscreen名を設定
        screenNode.position = SCNVector3(x: 0, y: 0, z: 0.041) // 本体の前面に配置
        phoneBodyNode.addChildNode(screenNode)
        
        print("Created placeholder model with screen node: \(screenNode.name ?? "unnamed")")
        
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
    
    func loadiPhoneModel(modelType: iPhoneModel) -> SCNScene? {
        return loadModel(named: modelType.rawValue)
    }
}

enum iPhoneModel: String, CaseIterable {
    case iPhone12 = "iphone12"
    case iPhone13 = "iphone13"
    case iPhone14 = "iphone14"
    case iPhone14Pro = "iphone14pro"
    case iPhone15 = "iphone15"
}
