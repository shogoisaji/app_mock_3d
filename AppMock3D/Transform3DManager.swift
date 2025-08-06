//
//  Transform3DManager.swift
//  AppMock3D
//
//  Created by Cascade on 2025/08/04.
//

import SceneKit

/// 3D Transform Manager Class
class Transform3DManager {
    /// Node to be manipulated
    private var targetNode: SCNNode?
    
    /// Initialize Transform3DManager
    /// - Parameter targetNode: SCNNode to be manipulated
    init(targetNode: SCNNode?) {
        self.targetNode = targetNode
    }
    
    /// Set the node's position
    /// - Parameter position: New position
    func setPosition(_ position: SCNVector3) {
        guard let node = targetNode else { return }
        node.position = position
    }
    
    /// Get the node's position
    /// - Returns: Current position
    func getPosition() -> SCNVector3? {
        return targetNode?.position
    }
    
    /// Move the node
    /// - Parameter translation: Amount of movement
    func translate(_ translation: SCNVector3) {
        guard let node = targetNode else { return }
        node.position.x += translation.x
        node.position.y += translation.y
        node.position.z += translation.z
        
        // Limit the movement range (implement as needed)
        // Example: Limit the movement range of each coordinate to between -10 and 10
        node.position.x = max(-10, min(10, node.position.x))
        node.position.y = max(-10, min(10, node.position.y))
        node.position.z = max(-10, min(10, node.position.z))
    }
    
    /// Set the node's scale
    /// - Parameter scale: New scale
    func setScale(_ scale: SCNVector3) {
        guard let node = targetNode else { return }
        node.scale = scale
    }
    
    /// Get the node's scale
    /// - Returns: Current scale
    func getScale() -> SCNVector3? {
        return targetNode?.scale
    }
    
    /// Scale the node
    /// - Parameter scale: Scaling factor
    func scale(_ scale: SCNVector3) {
        guard let node = targetNode else { return }
        node.scale.x *= scale.x
        node.scale.y *= scale.y
        node.scale.z *= scale.z
        
        // Limit the scaling range (0.5x to 3.0x)
        let minScale: Float = 0.5
        let maxScale: Float = 3.0
        
        node.scale.x = max(minScale, min(maxScale, node.scale.x))
        node.scale.y = max(minScale, min(maxScale, node.scale.y))
        node.scale.z = max(minScale, min(maxScale, node.scale.z))
    }
    
    /// Set the node's rotation
    /// - Parameter rotation: New rotation angle
    func setRotation(_ rotation: SCNVector3) {
        guard let node = targetNode else { return }
        node.eulerAngles = rotation
    }
    
    /// Get the node's rotation
    /// - Returns: Current rotation angle
    func getRotation() -> SCNVector3? {
        return targetNode?.eulerAngles
    }
    
    /// Rotate the node
    /// - Parameter rotation: Rotation angle
    func rotate(_ rotation: SCNVector3) {
        guard let node = targetNode else { return }
        node.eulerAngles.x += rotation.x
        node.eulerAngles.y += rotation.y
        node.eulerAngles.z += rotation.z
    }
    
    /// Reset the node's transform information
    func resetTransform() {
        guard let node = targetNode else { return }
        node.position = SCNVector3(0, 0, 0)
        node.scale = SCNVector3(1, 1, 1)
        node.eulerAngles = SCNVector3(0, 0, 0)
    }
}
