import SwiftUI
import SceneKit

struct GestureHandlingView: UIViewRepresentable {
    var scene: SCNScene
    @ObservedObject var appState: AppState

    // A variable to hold the reference to the main content node
    private var contentNode: SCNNode? {
        // Find the node to manipulate.
        // This could be improved by passing the node or using a specific name.
        scene.rootNode.childNode(withName: "model", recursively: true) ?? scene.rootNode.childNodes.first
    }
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        // Disable default camera controls to use custom gestures
        scnView.allowsCameraControl = false
        scnView.showsStatistics = true
        scnView.backgroundColor = UIColor.clear
        
        // Add pan gesture for rotation (1 finger) and translation (2 fingers)
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        scnView.addGestureRecognizer(panGesture)
        
        // Add pinch gesture for scaling
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        scnView.addGestureRecognizer(pinchGesture)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update view if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: GestureHandlingView
        var lastPanLocation: CGPoint = .zero
        var lastRotation: SCNVector3 = SCNVector3Zero

        init(_ parent: GestureHandlingView) {
            self.parent = parent
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let node = parent.contentNode else { return }
            
            let translation = gesture.translation(in: gesture.view)
            
            switch gesture.numberOfTouches {
            case 1: // 1-finger pan for rotation
                let rotationX = Float(translation.y) * 0.005
                let rotationY = Float(translation.x) * 0.005
                
                let newEulerX = node.eulerAngles.x + rotationX
                let newEulerY = node.eulerAngles.y + rotationY
                
                node.eulerAngles = SCNVector3(newEulerX, newEulerY, node.eulerAngles.z)
                
                // AppStateの値を同期
                parent.appState.setObjectEuler(node.eulerAngles)

            case 2: // 2-finger pan for movement
                let moveX = Float(translation.x) * 0.01
                let moveY = Float(translation.y) * -0.01 // Invert Y-axis for natural movement
                
                node.position.x += moveX
                node.position.y += moveY
                
                // AppStateの値を同期
                parent.appState.setObjectPosition(node.position)

            default:
                break
            }
            
            gesture.setTranslation(.zero, in: gesture.view)
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let node = parent.contentNode else { return }
            
            let scale = Float(gesture.scale)
            
            // Apply scale incrementally
            let newScaleX = node.scale.x * scale
            let newScaleY = node.scale.y * scale
            let newScaleZ = node.scale.z * scale
            
            node.scale = SCNVector3(newScaleX, newScaleY, newScaleZ)
            
            // AppStateの値を同期
            parent.appState.setObjectScale(node.scale)
            
            // Reset gesture scale to 1 for incremental scaling
            gesture.scale = 1.0
        }
    }
}
