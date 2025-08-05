import SceneKit
import UIKit

class RenderingEngine {
    private var scene: SCNScene
    private var renderer: SCNRenderer

    init(scene: SCNScene) {
        self.scene = scene
        self.renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
        self.scene = scene
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

            let renderSize = self.calculateRenderSize(aspectRatio: aspectRatio, baseResolution: baseResolution)

            let cameraNode = self.getOrCreateCameraNode()
            self.configureCamera(cameraNode)

            if let transform = cameraTransform {
                cameraNode.transform = transform
            }

            self.renderer.pointOfView = cameraNode
            self.renderer.isTemporalAntialiasingEnabled = antiAliasing > 1

            if let bgColor = backgroundColor {
                self.scene.background.contents = bgColor
            }

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

    private func getOrCreateCameraNode() -> SCNNode {
        if let existing = self.scene.rootNode.childNode(withName: "camera", recursively: true) {
            return existing
        } else {
            let node = SCNNode()
            node.name = "camera"
            node.camera = SCNCamera()
            node.position = SCNVector3(x: 0, y: 0, z: 5)
            node.look(at: SCNVector3(x: 0, y: 0, z: 0))
            self.scene.rootNode.addChildNode(node)
            return node
        }
    }

    private func configureCamera(_ node: SCNNode) {
        guard let camera = node.camera else { return }
        camera.fieldOfView = 60
        camera.automaticallyAdjustsZRange = true
        camera.zNear = 0.1
        camera.zFar = 100
    }

    private func calculateRenderSize(aspectRatio: Double, baseResolution: CGSize) -> CGSize {
        if aspectRatio > 1.0 {
            return CGSize(width: baseResolution.width,
                          height: baseResolution.width / aspectRatio)
        } else {
            return CGSize(width: baseResolution.height * aspectRatio,
                          height: baseResolution.height)
        }
    }
}