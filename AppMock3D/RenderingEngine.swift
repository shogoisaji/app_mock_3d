import SceneKit
import UIKit

class RenderingEngine {
    private var scene: SCNScene
    private var renderer: SCNRenderer
    
    init(scene: SCNScene) {
        self.scene = scene
        self.renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
        self.renderer.scene = scene
    }
    
    func renderImage(
        withQuality quality: ExportQuality,
        backgroundColor: UIColor? = nil,
        completion: @escaping (UIImage?) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let resolution = quality.resolution
            let antiAliasing = quality.antiAliasing
            let samplingQuality = quality.samplingQuality
            
            // レンダリング設定
            self.renderer.pointOfView = self.scene.rootNode.childNode(withName: "camera", recursively: true)
            self.renderer.isTemporalAntialiasingEnabled = antiAliasing > 1
            
            // 背景設定
            if let bgColor = backgroundColor {
                self.scene.background.contents = bgColor
            }
            
            // レンダリング実行
            let image = self.renderer.snapshot(
                atTime: 0,
                with: CGSize(width: resolution.width, height: resolution.height),
                antialiasingMode: antiAliasing > 1 ? .multisampling4X : .none
            )
            
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}
