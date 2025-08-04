//
//  Transform3DManager.swift
//  AppMock3D
//
//  Created by Cascade on 2025/08/04.
//

import SceneKit

/// 3D変換マネージャークラス
class Transform3DManager {
    /// 操作対象のノード
    private var targetNode: SCNNode?
    
    /// Transform3DManagerの初期化
    /// - Parameter targetNode: 操作対象のSCNNode
    init(targetNode: SCNNode?) {
        self.targetNode = targetNode
    }
    
    /// ノードの位置を設定する
    /// - Parameter position: 新しい位置
    func setPosition(_ position: SCNVector3) {
        guard let node = targetNode else { return }
        node.position = position
    }
    
    /// ノードの位置を取得する
    /// - Returns: 現在の位置
    func getPosition() -> SCNVector3? {
        return targetNode?.position
    }
    
    /// ノードを移動する
    /// - Parameter translation: 移動量
    func translate(_ translation: SCNVector3) {
        guard let node = targetNode else { return }
        node.position.x += translation.x
        node.position.y += translation.y
        node.position.z += translation.z
        
        // 移動範囲の制限（必要に応じて実装）
        // 例：各座標の移動範囲を-10から10の間に制限
        node.position.x = max(-10, min(10, node.position.x))
        node.position.y = max(-10, min(10, node.position.y))
        node.position.z = max(-10, min(10, node.position.z))
    }
    
    /// ノードのスケールを設定する
    /// - Parameter scale: 新しいスケール
    func setScale(_ scale: SCNVector3) {
        guard let node = targetNode else { return }
        node.scale = scale
    }
    
    /// ノードのスケールを取得する
    /// - Returns: 現在のスケール
    func getScale() -> SCNVector3? {
        return targetNode?.scale
    }
    
    /// ノードをスケーリングする
    /// - Parameter scale: スケーリング係数
    func scale(_ scale: SCNVector3) {
        guard let node = targetNode else { return }
        node.scale.x *= scale.x
        node.scale.y *= scale.y
        node.scale.z *= scale.z
        
        // スケーリング範囲の制限（0.5倍～3.0倍）
        let minScale: Float = 0.5
        let maxScale: Float = 3.0
        
        node.scale.x = max(minScale, min(maxScale, node.scale.x))
        node.scale.y = max(minScale, min(maxScale, node.scale.y))
        node.scale.z = max(minScale, min(maxScale, node.scale.z))
    }
    
    /// ノードの回転を設定する
    /// - Parameter rotation: 新しい回転角度
    func setRotation(_ rotation: SCNVector3) {
        guard let node = targetNode else { return }
        node.eulerAngles = rotation
    }
    
    /// ノードの回転を取得する
    /// - Returns: 現在の回転角度
    func getRotation() -> SCNVector3? {
        return targetNode?.eulerAngles
    }
    
    /// ノードを回転する
    /// - Parameter rotation: 回転角度
    func rotate(_ rotation: SCNVector3) {
        guard let node = targetNode else { return }
        node.eulerAngles.x += rotation.x
        node.eulerAngles.y += rotation.y
        node.eulerAngles.z += rotation.z
    }
    
    /// ノードの変換情報をリセットする
    func resetTransform() {
        guard let node = targetNode else { return }
        node.position = SCNVector3(0, 0, 0)
        node.scale = SCNVector3(1, 1, 1)
        node.eulerAngles = SCNVector3(0, 0, 0)
    }
}
