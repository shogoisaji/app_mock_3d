import SwiftUI
import SceneKit

struct ExportView: View {
    @State private var selectedQuality: ExportQuality = .high
    @State private var isExporting: Bool = false
    @State private var exportProgress: Double = 0.0
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    // Added: Preview image and loading state
    @State private var previewImage: UIImage?
    @State private var isLoadingPreview: Bool = true
    // Added: Track retry count for preview generation
    @State private var previewRetryCount: Int = 0
    // Added: Hold the current camera transform locally
    @State private var currentCameraTransform: SCNMatrix4?
    // Added: Hash value to detect changes in camera transform
    @State private var cameraTransformHash: Int = 0

    // Added: Dependencies received from the caller
    var renderingEngine: RenderingEngine?
    var photoSaveManager: PhotoSaveManager
    // Added: Latest camera posture of the preview (received as a Binding)
    @Binding var cameraTransform: SCNMatrix4?
    // Added: Aspect ratio of the preview
    var aspectRatio: Double = 1.0
    // Added: Snapshot image of the preview
    var previewSnapshot: UIImage? = nil
    
    // Added an initializer to handle the Binding properly
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
            Text("Export Settings")
                .font(.title)
                .padding()

            // MARK: - Preview Display Area
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
                Text("Could not generate preview")
                    .frame(height: 200)
            }
            
            Picker("Quality Settings", selection: $selectedQuality) {
                ForEach(ExportQuality.allCases, id: \.self) { quality in
                    Text(quality.displayName).tag(quality)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Button(action: {
                exportImage()
            }) {
                Text("Export Image")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(isExporting)
            
            if isExporting {
                ProgressView("Exporting...", value: exportProgress, total: 1.0)
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
            // If the camera transform has changed, regenerate the preview
            if newHash != cameraTransformHash {
                cameraTransformHash = newHash
                currentCameraTransform = cameraTransform
                previewRetryCount = 0 // Reset the retry counter
                generatePreview()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Export Result"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Preview Generation
    private func generatePreview() {
        isLoadingPreview = true
        
        // Use the snapshot image if it exists
        if let snapshot = previewSnapshot {
            previewImage = snapshot
            isLoadingPreview = false
        } else if let engine = renderingEngine {
            // If the camera transform is invalid or at its default value, retry
            if shouldRetryPreviewGeneration() && previewRetryCount < 3 {
                previewRetryCount += 1
                let delay = Double(previewRetryCount) * 0.1 // Gradually increase delay: 0.1s, 0.2s, 0.3s
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.generatePreview() // Recursively retry
                }
            } else {
                generatePreviewWithEngine(engine)
            }
        } else {
            // If neither is available
            previewImage = nil
            isLoadingPreview = false
        }
    }
    
    // Check if the camera transform is invalid or at its default value
    private func shouldRetryPreviewGeneration() -> Bool {
        let transform = currentCameraTransform ?? cameraTransform
        guard let transform = transform else {
            return true // Retry if transform is nil
        }
        
        // Check for default values (identity matrix or initial position at z=5)
        let isIdentityMatrix = SCNMatrix4EqualToMatrix4(transform, SCNMatrix4Identity)
        let isDefaultPosition = (transform.m41 == 0 && transform.m42 == 0 && transform.m43 == 5)
        
        return isIdentityMatrix || isDefaultPosition
    }
    
    // Generate preview with RenderingEngine
    private func generatePreviewWithEngine(_ engine: RenderingEngine) {
        // Use the latest camera transform
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
        
        // Save the snapshot image if it exists
        if let snapshot = previewSnapshot {
            saveImageToPhotoLibrary(snapshot)
        } else if let engine = renderingEngine {
            // Generate the image using RenderingEngine (fallback)
            let transformToUse = currentCameraTransform ?? cameraTransform
            engine.renderImage(
                withQuality: selectedQuality, 
                aspectRatio: aspectRatio, 
                cameraTransform: transformToUse
            ) { image in
                guard let image = image else {
                    self.isExporting = false
                    self.alertMessage = "Failed to export image."
                    self.showAlert = true
                    return
                }
                self.saveImageToPhotoLibrary(image)
            }
        } else {
            // If neither is available
            isExporting = false
            alertMessage = "Could not find the image data needed for export."
            showAlert = true
        }
    }
    
    private func saveImageToPhotoLibrary(_ image: UIImage) {
        let preferPNG = imageHasAlpha(image)
        photoSaveManager.saveImageToPhotoLibrary(image, preferPNG: preferPNG) { success, error in
            self.isExporting = false
            if success {
                self.alertMessage = "Image saved to photo library."
            } else {
                self.alertMessage = "Failed to save image: \(error?.localizedDescription ?? "Unknown error")"
            }
            self.showAlert = true
        }
    }

    private func imageHasAlpha(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        let alpha = cgImage.alphaInfo
        switch alpha {
        case .first, .last, .premultipliedFirst, .premultipliedLast:
            return true
        case .none, .noneSkipFirst, .noneSkipLast:
            return false
        @unknown default:
            return false
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
        alertMessage = "Export was cancelled"
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
