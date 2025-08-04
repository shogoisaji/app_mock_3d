import SceneKit
import Foundation

class ModelManager {
    static let shared = ModelManager()
    
    private init() {}
    
    func loadModel(named modelName: String) -> SCNScene? {
        // First try to load an actual OBJ file from the bundle
        if let scene = loadOBJModel(named: modelName) {
            return scene
        }
        
        // If no OBJ file is found, create a placeholder model
        return createPlaceholderModel()
    }
    
    private func loadOBJModel(named modelName: String) -> SCNScene? {
        // Try to load the OBJ file from the bundle
        guard let path = Bundle.main.path(forResource: modelName, ofType: "obj") else {
            return nil
        }
        
        do {
            let scene = try SCNScene(url: URL(fileURLWithPath: path), options: nil)
            return scene
        } catch {
            print("Failed to load OBJ model: \(error)")
            return nil
        }
    }
    
    private func createPlaceholderModel() -> SCNScene? {
        let scene = SCNScene()
        
        // Create a simple box as a placeholder for the iPhone model
        let box = SCNBox(width: 0.1, height: 0.2, length: 0.05, chamferRadius: 0.01)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        box.materials = [material]
        
        let boxNode = SCNNode(geometry: box)
        scene.rootNode.addChildNode(boxNode)
        
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
    case iPhone15 = "iphone15"
}
