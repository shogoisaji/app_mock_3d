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
    @State private var showingImagePicker = false
    @State private var isSaving = false
    @State private var showSaveSuccessAlert = false
    @State private var showSaveErrorAlert = false
    
    var body: some View {
        ZStack {
            // 3D プレビューは Safe Area を無視して全画面
            Group {
                if let scene = sceneView {
                    ZStack {
                        PreviewAreaView(scene: scene, appState: appState, imagePickerManager: imagePickerManager)
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
                    isSaving = true
                    if let scene = sceneView {
                        let renderingEngine = RenderingEngine(scene: scene)
                        renderingEngine.renderImage(withQuality: .high, backgroundColor: UIColor(appState.backgroundColor)) { image in
                            if let image = image {
                                photoSaveManager.saveImageToPhotoLibrary(image) { success, error in
                                    isSaving = false
                                    if success {
                                        showSaveSuccessAlert = true
                                    } else {
                                        showSaveErrorAlert = true
                                    }
                                }
                            } else {
                                isSaving = false
                                showSaveErrorAlert = true
                            }
                        }
                    }
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
            NavigationView {
                ImagePickerView(imagePickerManager: imagePickerManager, permissionManager: photoPermissionManager)
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
        .sheet(isPresented: $appState.isSettingsPresented) {
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
    }
    
    private func loadModel() {
        // Load the default iPhone model
        let model = ModelManager.shared.loadModel(named: "iphone14pro")
        
        if model == nil {
            appState.setImageError("3Dモデルの読み込みに失敗しました。アプリを再起動してください。")
        } else {
            sceneView = model
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

#Preview {
    ContentView()
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
