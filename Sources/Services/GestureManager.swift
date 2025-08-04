//
//  GestureManager.swift
//  AppMock3D
//
//  Created by Cascade on 2025/08/04.
//

import SwiftUI
import SceneKit

/// ジェスチャー管理クラス
class GestureManager: ObservableObject {
    @Published var currentMode: InteractionMode = .move
    @Published var isGestureActive = false
    
    private var sceneView: SCNView?
    private var targetNode: SCNNode?
    
    /// ジェスチャー管理の初期化
    /// - Parameters:
    ///   - sceneView: 操作対象のSCNView
    ///   - targetNode: 操作対象のSCNNode
    init(sceneView: SCNView?, targetNode: SCNNode?) {
        self.sceneView = sceneView
        self.targetNode = targetNode
    }
    
    /// 操作モードを切り替える
    /// - Parameter mode: 新しい操作モード
    func switchMode(to mode: InteractionMode) {
        currentMode = mode
    }
    
    /// ドラッグジェスチャーのハンドラー
    /// - Parameter value: ジェスチャーの値
    func handleDragGesture(_ value: DragGesture.Value) {
        guard let node = targetNode else { return }
        
        switch currentMode {
        case .move:
            handleMoveGesture(value, node: node)
        case .rotate:
            handleRotateGesture(value, node: node)
        default:
            break
        }
    }
    
    /// ピンチジェスチャーのハンドラー
    /// - Parameter value: ジェスチャーの値
    func handleMagnificationGesture(_ value: MagnificationGesture.Value) {
        guard let node = targetNode else { return }
        
        switch currentMode {
        case .scale:
            handleScaleGesture(value, node: node)
        default:
            break
        }
    }
    
    /// 回転ジェスチャーのハンドラー
    /// - Parameter value: ジェスチャーの値
    func handleRotationGesture(_ value: RotationGesture.Value) {
        guard let node = targetNode else { return }
        
        switch currentMode {
        case .rotate:
            handleRotateGesture(value, node: node)
        default:
            break
        }
    }
    
    /// 移動ジェスチャーの処理
    /// - Parameters:
    ///   - value: ジェスチャーの値
    ///   - node: 操作対象のノード
    private func handleMoveGesture(_ value: DragGesture.Value, node: SCNNode) {
        // X軸とY軸の移動を処理
        let translation = value.translation
        let moveX = Float(translation.x / 100)
        let moveY = Float(translation.y / 100)
        
        // Z軸の移動は2本指ドラッグで処理（別途実装が必要）
        node.position.x += moveX
        node.position.y -= moveY // Y座標は上がマイナスなので符号を反転
        
        // 移動範囲の制限（必要に応じて実装）
        // 例：x座標とy座標の移動範囲を-10から10の間に制限
        node.position.x = max(-10, min(10, node.position.x))
        node.position.y = max(-10, min(10, node.position.y))
    }
    
    /// 拡大縮小ジェスチャーの処理
    /// - Parameters:
    ///   - value: ジェスチャーの値
    ///   - node: 操作対象のノード
    private func handleScaleGesture(_ value: MagnificationGesture.Value, node: SCNNode) {
        // 拡大縮小の処理
        let scale = Float(value.magnification)
        node.scale = SCNVector3(scale, scale, scale)
        
        // 拡大縮小範囲の制限（0.5倍～3.0倍）
        let minScale: Float = 0.5
        let maxScale: Float = 3.0
        
        node.scale.x = max(minScale, min(maxScale, node.scale.x))
        node.scale.y = max(minScale, min(maxScale, node.scale.y))
        node.scale.z = max(minScale, min(maxScale, node.scale.z))
    }
    
    /// 回転ジェスチャーの処理
    /// - Parameters:
    ///   - value: ジェスチャーの値
    ///   - node: 操作対象のノード
    private func handleRotateGesture(_ value: DragGesture.Value, node: SCNNode) {
        // X軸とY軸の回転を処理
        let translation = value.translation
        let rotationX = Float(translation.y / 50)
        let rotationY = Float(translation.x / 50)
        
        node.eulerAngles.x += rotationX
        node.eulerAngles.y += rotationY
    }
    
    /// 回転ジェスチャーの処理（RotationGesture用）
    /// - Parameters:
    ///   - value: ジェスチャーの値
    ///   - node: 操作対象のノード
    private func handleRotateGesture(_ value: RotationGesture.Value, node: SCNNode) {
        // Z軸回転を処理
        let rotation = Float(value.rotation.radians)
        node.eulerAngles.z += rotation
    }
}
