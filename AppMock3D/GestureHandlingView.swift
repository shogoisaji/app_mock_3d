import SwiftUI
import SceneKit

struct GestureHandlingView: UIViewRepresentable {
    var scene: SCNScene
    @ObservedObject var appState: AppState
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        scnView.backgroundColor = UIColor.systemBackground
        
        // ジェスチャーを追加
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        scnView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        scnView.addGestureRecognizer(pinchGesture)
        
        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:)))
        scnView.addGestureRecognizer(rotationGesture)
        
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
        
        init(_ parent: GestureHandlingView) {
            self.parent = parent
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard parent.appState.currentMode == .move else { return }
            
            let translation = gesture.translation(in: gesture.view)
            // 移動処理の実装
            print("Pan gesture detected with translation: \(translation)")
            
            // ここで3Dオブジェクトの移動処理を実装
            // 例: selectedNode?.position = SCNVector3(selectedNode!.position.x + Float(translation.x), selectedNode!.position.y + Float(translation.y), selectedNode!.position.z)
            
            gesture.setTranslation(.zero, in: gesture.view)
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard parent.appState.currentMode == .scale else { return }
            
            let scale = gesture.scale
            // 拡大縮小処理の実装
            print("Pinch gesture detected with scale: \(scale)")
            
            // ここで3Dオブジェクトのスケーリング処理を実装
            // 例: selectedNode?.scale = SCNVector3(Float(scale), Float(scale), Float(scale))
            
            gesture.scale = 1.0
        }
        
        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard parent.appState.currentMode == .rotate else { return }
            
            let rotation = gesture.rotation
            // 回転処理の実装
            print("Rotation gesture detected with rotation: \(rotation)")
            
            // ここで3Dオブジェクトの回転処理を実装
            // 例: selectedNode?.eulerAngles = SCNVector3(selectedNode!.eulerAngles.x, selectedNode!.eulerAngles.y, Float(rotation))
            
            gesture.rotation = 0
        }
    }
}
