import Foundation
import SceneKit

class ExportOptimizer {
    private var isCancelled = false
    
    func optimizeExport(
        scene: SCNScene,
        quality: ExportQuality,
        progressHandler: @escaping (Double) -> Void,
        completion: @escaping (UIImage?, Error?) -> Void
    ) {
        isCancelled = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            // メモリ使用量の最適化
           autoreleasepool {
                // レンダリング設定
                let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
                renderer.scene = scene
                renderer.pointOfView = scene.rootNode.childNode(withName: "camera", recursively: true)
                renderer.isTemporalAntialiasingEnabled = quality.antiAliasing > 1
                
                // 進捗状況の更新
                progressHandler(0.5)
                
                // キャンセルチェック
                if self.isCancelled {
                    DispatchQueue.main.async {
                        completion(nil, NSError(domain: "ExportOptimizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Export was cancelled"]))
                    }
                    return
                }
                
                // レンダリング実行
                let image = renderer.snapshot(
                    atTime: 0,
                    with: CGSize(width: quality.resolution.width, height: quality.resolution.height),
                    antialiasingMode: quality.antiAliasing > 1 ? .multisampling4X : .none
                )
                
                // キャンセルチェック
                if self.isCancelled {
                    DispatchQueue.main.async {
                        completion(nil, NSError(domain: "ExportOptimizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Export was cancelled"]))
                    }
                    return
                }
                
                // 進捗状況の更新
                progressHandler(1.0)
                
                DispatchQueue.main.async {
                    completion(image, nil)
                }
            }
        }
    }
    
    func cancelExport() {
        isCancelled = true
    }
}
