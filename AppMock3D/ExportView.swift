import SwiftUI
import SceneKit

struct ExportView: View {
    @State private var selectedQuality: ExportQuality = .high
    @State private var isExporting: Bool = false
    @State private var exportProgress: Double = 0.0
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    // 追加: プレビュー画像と読み込み状態
    @State private var previewImage: UIImage?
    @State private var isLoadingPreview: Bool = true
    // 追加: プレビュー生成の再試行回数を追跡
    @State private var previewRetryCount: Int = 0
    // 追加: 現在のカメラトランスフォームをローカルで保持
    @State private var currentCameraTransform: SCNMatrix4?
    // 追加: カメラトランスフォームの変更を検出するためのハッシュ値
    @State private var cameraTransformHash: Int = 0

    // 追加: 呼び出し元から受け取る依存
    var renderingEngine: RenderingEngine?
    var photoSaveManager: PhotoSaveManager
    // 追加: プレビューの最新カメラ姿勢（Bindingで受け取る）
    @Binding var cameraTransform: SCNMatrix4?
    // 追加: プレビューのアスペクト比
    var aspectRatio: Double = 1.0
    // 追加: プレビューのスナップショット画像
    var previewSnapshot: UIImage? = nil
    
    // 初期化メソッドを追加してBindingを適切に扱う
    init(renderingEngine: RenderingEngine?, 
         photoSaveManager: PhotoSaveManager, 
         cameraTransform: Binding<SCNMatrix4?>, 
         aspectRatio: Double = 1.0, 
         previewSnapshot: UIImage? = nil) {
        self.renderingEngine = renderingEngine
        self.photoSaveManager = photoSaveManager
        self._cameraTransform = cameraTransform
        self.aspectRatio = aspectRatio
        self.previewSnapshot = previewSnapshot
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("エクスポート設定")
                .font(.title)
                .padding()

            // MARK: - プレビュー表示エリア
            if isLoadingPreview {
                ProgressView()
                    .frame(height: 200)
                    .accessibilityIdentifier("PreviewLoadingIndicator")
            } else if let preview = previewImage {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .accessibilityIdentifier("ExportPreviewImage")
            } else {
                Text("プレビューを生成できませんでした")
                    .frame(height: 200)
            }
            
            Picker("品質設定", selection: $selectedQuality) {
                ForEach(ExportQuality.allCases, id: \.self) { quality in
                    Text(quality.displayName).tag(quality)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Button(action: {
                exportImage()
            }) {
                Text("画像をエクスポート")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(isExporting)
            
            if isExporting {
                ProgressView("エクスポート中...", value: exportProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
            }
            
            Spacer()
        }
        .onAppear {
            currentCameraTransform = cameraTransform
            cameraTransformHash = hashMatrix(cameraTransform)
            generatePreview()
        }
        .onChange(of: hashMatrix(cameraTransform)) { _, newHash in
            // カメラトランスフォームが変更された場合、プレビューを再生成
            if newHash != cameraTransformHash {
                cameraTransformHash = newHash
                currentCameraTransform = cameraTransform
                previewRetryCount = 0 // 再試行カウンターをリセット
                generatePreview()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("エクスポート結果"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - プレビュー生成
    private func generatePreview() {
        isLoadingPreview = true
        
        // スナップショット画像がある場合はそれを使用
        if let snapshot = previewSnapshot {
            previewImage = snapshot
            isLoadingPreview = false
        } else if let engine = renderingEngine {
            // カメラトランスフォームが無効またはデフォルト値の場合、再試行
            if shouldRetryPreviewGeneration() && previewRetryCount < 3 {
                previewRetryCount += 1
                let delay = Double(previewRetryCount) * 0.1 // 0.1秒, 0.2秒, 0.3秒と徐々に遅延
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.generatePreview() // 再帰的に再試行
                }
            } else {
                generatePreviewWithEngine(engine)
            }
        } else {
            // どちらも利用できない場合
            previewImage = nil
            isLoadingPreview = false
        }
    }
    
    // カメラトランスフォームが無効またはデフォルト値かチェック
    private func shouldRetryPreviewGeneration() -> Bool {
        let transform = currentCameraTransform ?? cameraTransform
        guard let transform = transform else {
            return true // transformがnilの場合は再試行
        }
        
        // デフォルト値（単位行列やz=5の初期位置）をチェック
        let isIdentityMatrix = SCNMatrix4EqualToMatrix4(transform, SCNMatrix4Identity)
        let isDefaultPosition = (transform.m41 == 0 && transform.m42 == 0 && transform.m43 == 5)
        
        return isIdentityMatrix || isDefaultPosition
    }
    
    // RenderingEngineでプレビューを生成
    private func generatePreviewWithEngine(_ engine: RenderingEngine) {
        // 最新のカメラトランスフォームを使用
        let transformToUse = currentCameraTransform ?? cameraTransform
        engine.renderImage(
            withQuality: .low, 
            aspectRatio: aspectRatio, 
            cameraTransform: transformToUse
        ) { image in
            self.previewImage = image
            self.isLoadingPreview = false
        }
    }
    
    private func exportImage() {
        isExporting = true
        exportProgress = 0.0
        
        // スナップショット画像がある場合はそれを保存
        if let snapshot = previewSnapshot {
            saveImageToPhotoLibrary(snapshot)
        } else if let engine = renderingEngine {
            // RenderingEngine を使って画像を生成（フォールバック）
            let transformToUse = currentCameraTransform ?? cameraTransform
            engine.renderImage(
                withQuality: selectedQuality, 
                aspectRatio: aspectRatio, 
                cameraTransform: transformToUse
            ) { image in
                guard let image = image else {
                    self.isExporting = false
                    self.alertMessage = "画像のエクスポートに失敗しました。"
                    self.showAlert = true
                    return
                }
                self.saveImageToPhotoLibrary(image)
            }
        } else {
            // どちらも利用できない場合
            isExporting = false
            alertMessage = "エクスポートに必要な画像データが見つかりません。"
            showAlert = true
        }
    }
    
    private func saveImageToPhotoLibrary(_ image: UIImage) {
        photoSaveManager.saveImageToPhotoLibrary(image) { success, error in
            self.isExporting = false
            if success {
                self.alertMessage = "画像が写真ライブラリに保存されました。"
            } else {
                self.alertMessage = "画像の保存に失敗しました: \(error?.localizedDescription ?? "不明なエラー")"
            }
            self.showAlert = true
        }
    }
    
    // RenderingEngine の scene 内カメラノードを取得して姿勢を適用するためのヘルパ
    private func renderingEngineValuePointOfView() -> SCNNode? {
        guard let engine = renderingEngine else { return nil }
        
        // RenderingEngine は内部に scene を持ち、scene.rootNode に "camera" がある前提
        // 直接アクセス手段がないため、エクスポート前に渡した scene 内の camera を参照する
        // ここでは renderer.pointOfView を上書きするため camera ノードを取得
        // RenderingEngine の実装では render 時に pointOfView を "camera" 名で探して設定しているため、
        // ここで camera ノードの transform を先に更新しておけば一致する。
        // scene は RenderingEngine 初期化時に渡されたものの参照が生きている。
        // その rootNode から名前検索する。
        let mirror = Mirror(reflecting: engine)
        for child in mirror.children {
            if child.label == "scene", let scene = child.value as? SCNScene {
                return scene.rootNode.childNode(withName: "camera", recursively: true)
            }
        }
        return nil
    }
    
    private func cancelExport() {
        isExporting = false
        alertMessage = "エクスポートがキャンセルされました"
        showAlert = true
    }
    
    // SCNMatrix4のハッシュ値を計算するヘルパー関数
    private func hashMatrix(_ matrix: SCNMatrix4?) -> Int {
        guard let matrix = matrix else { return 0 }
        
        var hasher = Hasher()
        hasher.combine(matrix.m11)
        hasher.combine(matrix.m12)
        hasher.combine(matrix.m13)
        hasher.combine(matrix.m14)
        hasher.combine(matrix.m21)
        hasher.combine(matrix.m22)
        hasher.combine(matrix.m23)
        hasher.combine(matrix.m24)
        hasher.combine(matrix.m31)
        hasher.combine(matrix.m32)
        hasher.combine(matrix.m33)
        hasher.combine(matrix.m34)
        hasher.combine(matrix.m41)
        hasher.combine(matrix.m42)
        hasher.combine(matrix.m43)
        hasher.combine(matrix.m44)
        
        return hasher.finalize()
    }
}
