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
        aspectRatio: Double = 1.0,
        backgroundColor: UIColor? = nil,
        cameraTransform: SCNMatrix4? = nil,
        completion: @escaping (UIImage?) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let baseResolution = quality.resolution
            let antiAliasing = quality.antiAliasing
            let _ = quality.samplingQuality
            
            // アスペクト比を考慮した解像度を計算
            let renderSize: CGSize
            if aspectRatio > 1.0 {
                // 横長の場合：幅を基準にして高さを調整
                renderSize = CGSize(
                    width: baseResolution.width,
                    height: baseResolution.width / aspectRatio
                )
            } else {
                // 縦長または正方形の場合：高さを基準にして幅を調整
                renderSize = CGSize(
                    width: baseResolution.height * aspectRatio,
                    height: baseResolution.height
                )
            }
            
            // 既存のカメラノードを取得（存在しない場合のみ新規作成）
            let cameraNode = self.scene.rootNode.childNode(withName: "camera", recursively: true) ?? {
                let node = SCNNode()
                node.name = "camera"
                node.camera = SCNCamera()
                // デフォルト位置を設定
                node.position = SCNVector3(x: 0, y: 0, z: 5)
                node.look(at: SCNVector3(x: 0, y: 0, z: 0))
                self.scene.rootNode.addChildNode(node)
                return node
            }()
            
            // プレビューと同じカメラ設定を適用
            if let camera = cameraNode.camera {
                camera.fieldOfView = 60
                camera.automaticallyAdjustsZRange = true
                camera.zNear = 0.1
                camera.zFar = 100
                // アスペクト比はレンダリングサイズで制御される
            }
            
            // カメラ変換行列が渡されている場合は適用
            if let transform = cameraTransform {
                cameraNode.transform = transform
            }
            
            self.renderer.pointOfView = cameraNode
            self.renderer.isTemporalAntialiasingEnabled = antiAliasing > 1
            
            // 背景設定
            if let bgColor = backgroundColor {
                self.scene.background.contents = bgColor
            }
            
            // レンダリング実行
            let image = self.renderer.snapshot(
                atTime: 0,
                with: renderSize,
                antialiasingMode: antiAliasing > 1 ? .multisampling4X : .none
            )
            
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}
