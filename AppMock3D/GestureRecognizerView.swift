//
//  GestureRecognizerView.swift
//  AppMock3D
//
//  Created by Cascade on 2025/08/04.
//

import SwiftUI
import SceneKit

/// ジェスチャー認識ビュー
struct GestureRecognizerView: View {
    @ObservedObject var gestureManager: GestureManager
    var sceneView: SCNView?
    var targetNode: SCNNode?
    
    var body: some View {
        ZStack {
            // 3Dビューを表示
            SceneKitView(sceneView: sceneView)
            
            // 透明なビューにジェスチャーを適用
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    SimultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                gestureManager.isGestureActive = true
                                gestureManager.handleDragGesture(value)
                            }
                            .onEnded { value in
                                gestureManager.isGestureActive = false
                            },
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    gestureManager.isGestureActive = true
                                    gestureManager.handleMagnificationGesture(value)
                                }
                                .onEnded { value in
                                    gestureManager.isGestureActive = false
                                },
                            RotationGesture()
                                .onChanged { value in
                                    gestureManager.isGestureActive = true
                                    gestureManager.handleRotationGesture(value)
                                }
                                .onEnded { value in
                                    gestureManager.isGestureActive = false
                                }
                        )
                    )
                )
        }
    }
}

/// SceneKitビューのラッパー
struct SceneKitView: UIViewRepresentable {
    var sceneView: SCNView?
    
    func makeUIView(context: Context) -> SCNView {
        return sceneView ?? SCNView()
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // 更新処理（必要に応じて実装）
    }
}
