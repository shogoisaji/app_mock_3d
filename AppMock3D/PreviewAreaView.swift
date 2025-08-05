import SwiftUI
import SceneKit

struct PreviewAreaView: View {
    let originalScene: SCNScene
    @ObservedObject var appState: AppState
    @ObservedObject var imagePickerManager: ImagePickerManager
    @State private var currentScene: SCNScene
    // 追加: 現在のシーン更新を親へ伝える
    var onSceneUpdated: ((SCNScene) -> Void)? = nil
    // 追加: カメラ姿勢更新を親へ伝える
    var onCameraUpdated: ((SCNMatrix4) -> Void)? = nil
    // 追加: スナップショット要求を受け取るコールバック
    var onSnapshotRequested: ((UIImage?) -> Void)? = nil
    // 追加: スナップショット要求のトリガー
    @Binding var shouldTakeSnapshot: Bool
    
    init(scene: SCNScene, appState: AppState, imagePickerManager: ImagePickerManager, shouldTakeSnapshot: Binding<Bool>, onSceneUpdated: ((SCNScene) -> Void)? = nil, onCameraUpdated: ((SCNMatrix4) -> Void)? = nil, onSnapshotRequested: ((UIImage?) -> Void)? = nil) {
        self.originalScene = scene
        self.appState = appState
        self.imagePickerManager = imagePickerManager
        self._currentScene = State(initialValue: scene)
        self._shouldTakeSnapshot = shouldTakeSnapshot
        self.onSceneUpdated = onSceneUpdated
        self.onCameraUpdated = onCameraUpdated
        self.onSnapshotRequested = onSnapshotRequested
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Darken the area outside the viewport
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                
                // 1) プレビュー領域のサイズを算出（白枠）
                let previewWidth = geometry.size.width
                let previewHeight = geometry.size.width / appState.aspectRatio
                let previewSize = CGSize(width: previewWidth, height: previewHeight)
                
                // 2) SCNView を重ね、見た目のままあとでキャプチャできるようにホスト
                SnapshotHostingView(scene: currentScene, previewSize: previewSize, shouldTakeSnapshot: $shouldTakeSnapshot, onCameraUpdate: { transform in
                    // Coordinator からカメラ姿勢を受け取り、親へ通知
                    onCameraUpdated?(transform)
                }, onSnapshotRequested: onSnapshotRequested)
                    .frame(width: previewWidth, height: previewHeight)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: PreviewFramePreferenceKey.self,
                                            value: proxy.frame(in: .global))
                        }
                    )
                    .border(Color.white, width: 2)
                    .clipped()
                    .animation(.easeInOut(duration: 0.3), value: currentScene)
                
                // 画像が選択されていない場合の案内表示
                if imagePickerManager.selectedImage == nil && !appState.isImageProcessing {
                    VStack {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.7))
                        Text("上の📷ボタンから画像を選択")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
                }
            }
            .onChange(of: imagePickerManager.selectedImage) { _, newImage in
                updateSceneWithImage(newImage, size: geometry.size)
            }
            .onChange(of: appState.settings) { _, newSettings in
                updateSceneBackground(newSettings, size: geometry.size)
            }
            .onAppear {
                updateSceneBackground(appState.settings, size: geometry.size)
                // 初回表示時にも現在シーンを通知
                onSceneUpdated?(currentScene)
                // カメラ行列も初期通知（存在する場合）
                if let pov = currentScene.rootNode.childNode(withName: "camera", recursively: true) {
                    onCameraUpdated?(pov.transform)
                }
            }
            // 白枠の CGRect を外へ伝達（必要に応じて使用）
            .onPreferenceChange(PreviewFramePreferenceKey.self) { frame in
                // 今後 ContentView/ExportView 側へ座標を渡したい場合に利用
                // print("Preview frame (global): \(frame)")
            }
            .onChange(of: shouldTakeSnapshot) { _, newValue in
                if newValue {
                    // スナップショット要求が来たときの処理
                    // SnapshotHostingViewが自動的にスナップショットを取得する
                    // フラグのリセットはSnapshotHostingView内で行われる
                }
            }
        }
    }
    
    private func updateSceneWithImage(_ image: UIImage?, size: CGSize) {
        guard let image = image else {
            // 画像がクリアされた場合、元のシーンに戻す
            appState.clearImageState()
            withAnimation(.easeInOut(duration: 0.3)) {
                currentScene = originalScene
                updateSceneBackground(appState.settings, size: size)
            }
            // 親へ最新シーンを通知（初期シーンに戻す）
            onSceneUpdated?(originalScene)
            return
        }
        
        // 画像の有効性をチェック
        guard image.size.width > 0 && image.size.height > 0 else {
            DispatchQueue.main.async {
                appState.setImageError("無効な画像です。別の画像を選択してください。")
            }
            return
        }
        
        // 処理開始を通知
        DispatchQueue.main.async {
            appState.setImageProcessing(true)
        }
        
        // 非同期でテクスチャを適用
        DispatchQueue.global(qos: .userInitiated).async {
            // メモリ使用量をチェック
            let memoryUsage = Self.getMemoryUsage()
            if memoryUsage > 0.8 { // 80%以上の場合
                TextureManager.shared.clearCache()
            }
            
            // テクスチャ適用を実行
            if let updatedScene = TextureManager.shared.applyTextureToModel(originalScene, image: image) {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentScene = updatedScene
                        updateSceneBackground(appState.settings, size: size)
                    }
                    // 親へ最新シーンを通知
                    onSceneUpdated?(updatedScene)
                    appState.setImageApplied(true)
                    appState.setImageProcessing(false)
                }
            } else {
                DispatchQueue.main.async {
                    appState.setImageError("テクスチャの適用に失敗しました。3Dモデルに画面が見つからない可能性があります。")
                }
            }
        }
    }

    private func updateSceneBackground(_ settings: AppSettings, size: CGSize) {
        switch settings.backgroundColor {
        case .solidColor:
            currentScene.background.contents = UIColor(Color(hex: settings.solidColorValue) ?? .white)
        case .gradient:
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = CGRect(origin: .zero, size: size)
            gradientLayer.colors = [
                UIColor(Color(hex: settings.gradientStartColor) ?? .white).cgColor,
                UIColor(Color(hex: settings.gradientEndColor) ?? .black).cgColor
            ]
            if settings.gradientType == .linear {
                gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
                gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
            } else {
                gradientLayer.type = .radial
                gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
                gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            }
            
            UIGraphicsBeginImageContext(gradientLayer.bounds.size)
            gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            currentScene.background.contents = image
        case .transparent:
            currentScene.background.contents = UIColor.clear
        }
    }
    
    private static func getMemoryUsage() -> Float {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Float(info.resident_size) / 1024.0 / 1024.0 // MB
            let totalMemory = Float(ProcessInfo.processInfo.physicalMemory) / 1024.0 / 1024.0 / 1024.0 // GB
            return usedMemory / (totalMemory * 1024.0) // 使用率を返す
        } else {
            return 0.0
        }
    }
    
    // MARK: - 白枠のフレームを伝えるための PreferenceKey
    private struct PreviewFramePreferenceKey: PreferenceKey {
        static var defaultValue: CGRect = .zero
        static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
            value = nextValue()
        }
    }
}

/// SCNView を SwiftUI 上にホストして、白枠サイズで見えているまま snapshot を取得できるようにするビュー
private struct SnapshotHostingView: UIViewRepresentable {
    var scene: SCNScene
    var previewSize: CGSize
    @Binding var shouldTakeSnapshot: Bool
    // 追加: カメラ姿勢の更新を通知するコールバック
    var onCameraUpdate: ((SCNMatrix4) -> Void)?
    // 追加: スナップショット要求を受け取るコールバック
    var onSnapshotRequested: ((UIImage?) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onCameraUpdate: onCameraUpdate, onSnapshotRequested: onSnapshotRequested)
    }
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView(frame: CGRect(origin: .zero, size: previewSize))
        scnView.translatesAutoresizingMaskIntoConstraints = false
        scnView.scene = scene
        scnView.backgroundColor = .clear
        // プレビューと同じ操作性
        scnView.allowsCameraControl = true
        scnView.showsStatistics = false
        scnView.antialiasingMode = .multisampling4X
        scnView.preferredFramesPerSecond = 60
        scnView.insetsLayoutMarginsFromSafeArea = false
        scnView.contentMode = .scaleAspectFill
        scnView.layer.masksToBounds = true
        
        // デリゲートを設定してカメラの更新を検知
        scnView.delegate = context.coordinator
        
        // Coordinatorに SCNView の参照を渡す
        context.coordinator.scnView = scnView
        
        // 照明/カメラセットアップ（ContentView.PreviewView と整合）
        setupLighting(for: scene)
        setupCamera(for: scene)
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.scene = scene
        uiView.delegate = context.coordinator
        uiView.insetsLayoutMarginsFromSafeArea = false
        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()
        
        // Coordinatorの SCNView 参照を更新
        context.coordinator.scnView = uiView
        
        // スナップショット要求が来ている場合
        if shouldTakeSnapshot {
            context.coordinator.takeSnapshot()
            // フラグをリセット
            DispatchQueue.main.async {
                shouldTakeSnapshot = false
            }
        }
    }
    
    // 現在の見た目を白枠サイズそのままでスナップショット
    // 注意: UIViewRepresentable の makeUIView を直接呼ばず、表示中の SCNView の snapshot を使う
    func snapshotImage(from uiView: SCNView) -> UIImage? {
        // SCNView の snapshot() は現在のカメラ状態・描画内容を反映
        let raw = uiView.snapshot()
        // すでに previewSize でフレーム設定しているため、そのまま返せる
        return raw
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

    // MARK: - Coordinator
    class Coordinator: NSObject, SCNSceneRendererDelegate {
        var onCameraUpdate: ((SCNMatrix4) -> Void)?
        var onSnapshotRequested: ((UIImage?) -> Void)?
        var scnView: SCNView?

        init(onCameraUpdate: ((SCNMatrix4) -> Void)?, onSnapshotRequested: ((UIImage?) -> Void)?) {
            self.onCameraUpdate = onCameraUpdate
            self.onSnapshotRequested = onSnapshotRequested
            super.init()
        }

        func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
            // カメラの transform (姿勢) を取得して通知
            if let pov = renderer.pointOfView {
                onCameraUpdate?(pov.transform)
            }
        }
        
        func takeSnapshot() {
            guard let scnView = scnView else {
                onSnapshotRequested?(nil)
                return
            }
            
            DispatchQueue.main.async {
                let snapshot = scnView.snapshot()
                self.onSnapshotRequested?(snapshot)
            }
        }
    }
}

struct PreviewAreaView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewAreaViewWrapper()
    }
}

private struct PreviewAreaViewWrapper: View {
    @State private var shouldTakeSnapshot = false
    
    var body: some View {
        let scene = SCNScene()
        let box = SCNBox(width: 0.1, height: 0.2, length: 0.05, chamferRadius: 0.01)
        let boxNode = SCNNode(geometry: box)
        scene.rootNode.addChildNode(boxNode)
        
        return PreviewAreaView(scene: scene, appState: AppState(), imagePickerManager: ImagePickerManager(), shouldTakeSnapshot: $shouldTakeSnapshot)
    }
}
