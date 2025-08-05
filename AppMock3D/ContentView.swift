//
//  ContentView.swift
//  AppMock3D
//
//  Created by shogo isaji on 2025/08/04.
//

import SwiftUI
import SceneKit
import UIKit
import Foundation

struct ContentView: View {
    @StateObject private var appState = AppState()
    @StateObject private var imagePickerManager = ImagePickerManager()
    @StateObject private var photoPermissionManager = PhotoPermissionManager()
    @StateObject private var photoSaveManager = PhotoSaveManager()
    @State private var sceneView: SCNScene?
    // 追加: エクスポート用に最新シーンを保持
    @State private var latestSceneForExport: SCNScene?
    @State private var showingImagePicker = false
    @State private var isSaving = false
    @State private var showSaveSuccessAlert = false
    @State private var showSaveErrorAlert = false
    @State private var showingExportView = false
    // 追加: プレビューのカメラ行列を保持
    @State private var latestCameraTransform: SCNMatrix4?
    // 追加: プレビューのスナップショット画像を保持
    @State private var currentPreviewSnapshot: UIImage?
    // 追加: スナップショット要求のトリガー
    @State private var shouldTakeSnapshot = false
    
    var body: some View {
        ZStack {
            // 3D プレビューは Safe Area を無視して全画面
            Group {
                if let scene = sceneView {
                    ZStack {
                        PreviewAreaView(scene: scene, appState: appState, imagePickerManager: imagePickerManager, shouldTakeSnapshot: $shouldTakeSnapshot, onSceneUpdated: { updated in
                            // 最新のシーンを保持（エクスポートに使用）
                            latestSceneForExport = updated
                        }, onCameraUpdated: { transform in
                            // カメラ姿勢をリアルタイムで更新
                            latestCameraTransform = transform
                        }, onSnapshotRequested: { snapshot in
                            // スナップショット画像を受け取る
                            currentPreviewSnapshot = snapshot
                            // スナップショット取得後にExportViewを表示
                            showingExportView = true
                        })
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .accessibilityIdentifier("3D Preview")
                        
                        // ローディング状態の表示
                        if appState.isImageProcessing {
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("画像を処理中...")
                                    .foregroundColor(.white)
                                    .padding(.top)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.5))
                        }
                        
                        // エラー状態の表示
                        if let error = appState.imageError {
                            VStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.red)
                                Text("エラー")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                Button("再試行") {
                                    appState.clearImageState()
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(8)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.7))
                        }
                        
                        // 保存中の表示
                        if isSaving {
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("画像を保存中...")
                                    .foregroundColor(.white)
                                    .padding(.top)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.5))
                        }
                    }
                } else {
                    Text("3Dモデルを読み込んでいます...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityIdentifier("Loading 3D Model")
                }
            }
            .ignoresSafeArea(edges: .all) // プレビューは端まで
            
            // AppBar / BottomNav は Safe Area 内に保持
            VStack(spacing: 0) {
                // 上部 AppBar（Safe Area 内）
                AppBarView(title: "", onSave: {
                    // スナップショット要求をトリガー
                    shouldTakeSnapshot = true
                }, onSettings: {
                    appState.toggleSettings()
                }, onImageSelect: {
                    showingImagePicker = true
                })
                .accessibilityIdentifier("AppBar")
                .padding(.top, 0)
                
                Spacer()
                
                
            }
            .padding(.horizontal, 0)
            // Safe Area を尊重（ここでは ignoresSafeArea を適用しない）
        }
        .onAppear {
            loadModel()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerSheetView(showingImagePicker: $showingImagePicker, imagePickerManager: imagePickerManager, permissionManager: photoPermissionManager)
        }
        .sheet(isPresented: $appState.isSettingsPresented) {
            SettingsSheetView(appState: appState)
        }
        .alert("保存完了", isPresented: $showSaveSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("画像をフォトライブラリに保存しました。")
        }
        .alert("保存エラー", isPresented: $showSaveErrorAlert) {
            Button("OK") { }
        } message: {
            Text("画像の保存に失敗しました。")
        }
        .sheet(isPresented: $showingExportView) {
            // スナップショット画像がある場合はそれを使用
            if let snapshot = currentPreviewSnapshot {
                ExportView(renderingEngine: nil,
                           photoSaveManager: PhotoSaveManager(),
                           cameraTransform: latestCameraTransform,
                           aspectRatio: appState.aspectRatio,
                           previewSnapshot: snapshot)
            } else if let exportScene = latestSceneForExport ?? sceneView {
                // フォールバック: RenderingEngineを使用
                let renderingEngine = RenderingEngine(scene: exportScene)
                ExportView(renderingEngine: renderingEngine,
                           photoSaveManager: PhotoSaveManager(),
                           cameraTransform: latestCameraTransform,
                           aspectRatio: appState.aspectRatio,
                           previewSnapshot: nil)
            } else {
                Text("エクスポートするシーンがありません。")
            }
        }
    }
    
    private func loadModel() {
        // Load the default iPhone model
        let model = ModelManager.shared.loadModel(named: "iphone14pro")
        
        if model == nil {
            appState.setImageError("3Dモデルの読み込みに失敗しました。アプリを再起動してください。")
        } else {
            sceneView = model
            // 初期ロード時点のシーンをエクスポート用にセット
            latestSceneForExport = model
        }
    }
}

struct ImagePickerSheetView: View {
    @Binding var showingImagePicker: Bool
    @ObservedObject var imagePickerManager: ImagePickerManager
    @ObservedObject var permissionManager: PhotoPermissionManager

    var body: some View {
        NavigationView {
            ImagePickerView(imagePickerManager: imagePickerManager, permissionManager: permissionManager)
                .navigationTitle("画像を選択")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("キャンセル") {
                            showingImagePicker = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完了") {
                            showingImagePicker = false
                        }
                        .disabled(imagePickerManager.selectedImage == nil)
                    }
                }
        }
    }
}

struct PreviewView: UIViewRepresentable {
    var scene: SCNScene
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView(frame: .zero)
        scnView.translatesAutoresizingMaskIntoConstraints = false
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.showsStatistics = false
        scnView.backgroundColor = UIColor.black
        scnView.antialiasingMode = .multisampling4X
        scnView.preferredFramesPerSecond = 60

        // Safe Area を無視してフルスクリーンに広がるように
        scnView.insetsLayoutMarginsFromSafeArea = false
        scnView.contentMode = .scaleAspectFill
        scnView.layer.masksToBounds = false

        setupLighting(for: scene)
        setupCamera(for: scene)
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.scene = scene
        uiView.insetsLayoutMarginsFromSafeArea = false
        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()
    }
    
    private func setupLighting(for scene: SCNScene) {
        if scene.rootNode.childNode(withName: "mainLight", recursively: false) != nil {
            return
        }
        let lightNode = SCNNode()
        lightNode.name = "mainLight"
        lightNode.light = SCNLight()
        lightNode.light!.type = .directional
        lightNode.light!.color = UIColor.white
        lightNode.light!.intensity = 1000
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        lightNode.eulerAngles = SCNVector3(x: -Float.pi/4, y: 0, z: 0)
        scene.rootNode.addChildNode(lightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.name = "ambientLight"
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor(white: 0.3, alpha: 1.0)
        ambientLightNode.light!.intensity = 400
        scene.rootNode.addChildNode(ambientLightNode)
        
        let fillLightNode = SCNNode()
        fillLightNode.name = "fillLight"
        fillLightNode.light = SCNLight()
        fillLightNode.light!.type = .omni
        fillLightNode.light!.color = UIColor(white: 0.6, alpha: 1.0)
        fillLightNode.light!.intensity = 200
        fillLightNode.position = SCNVector3(x: -5, y: 5, z: 5)
        scene.rootNode.addChildNode(fillLightNode)
    }
    
    private func setupCamera(for scene: SCNScene) {
        let cameraNode = scene.rootNode.childNode(withName: "camera", recursively: true) ?? {
            let node = SCNNode()
            node.name = "camera"
            node.camera = SCNCamera()
            scene.rootNode.addChildNode(node)
            return node
        }()
        if let camera = cameraNode.camera {
            camera.fieldOfView = 60
            camera.automaticallyAdjustsZRange = true
            camera.zNear = 0.1
            camera.zFar = 100
        }
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
    }
}

struct SettingsSheetView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        NavigationView {
            SettingsView(appState: appState)
                .navigationTitle("設定")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完了") {
                            appState.isSettingsPresented = false
                        }
                    }
                }
        }
    }
}




