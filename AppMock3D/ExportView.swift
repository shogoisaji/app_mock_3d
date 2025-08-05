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

    // 追加: 呼び出し元から受け取る依存
    var renderingEngine: RenderingEngine?
    var photoSaveManager: PhotoSaveManager
    // 追加: プレビューの最新カメラ姿勢（任意）
    var cameraTransform: SCNMatrix4? = nil
    // 追加: プレビューのアスペクト比
    var aspectRatio: Double = 1.0
    // 追加: プレビューのスナップショット画像
    var previewSnapshot: UIImage? = nil
    
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
        .onAppear(perform: generatePreview)
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
            // RenderingEngineでプレビューを生成（フォールバック）
            engine.renderImage(
                withQuality: .low, 
                aspectRatio: aspectRatio, 
                cameraTransform: cameraTransform
            ) { image in
                self.previewImage = image
                self.isLoadingPreview = false
            }
        } else {
            // どちらも利用できない場合
            previewImage = nil
            isLoadingPreview = false
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
            engine.renderImage(
                withQuality: selectedQuality, 
                aspectRatio: aspectRatio, 
                cameraTransform: cameraTransform
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
}
