import SwiftUI
import SceneKit

struct PreviewAreaView: View {
    let originalScene: SCNScene
    @ObservedObject var appState: AppState
    @ObservedObject var imagePickerManager: ImagePickerManager
    @State private var currentScene: SCNScene
    
    init(scene: SCNScene, appState: AppState, imagePickerManager: ImagePickerManager) {
        self.originalScene = scene
        self.appState = appState
        self.imagePickerManager = imagePickerManager
        self._currentScene = State(initialValue: scene)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Darken the area outside the viewport
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                
                // Preview area with border
                PreviewView(scene: currentScene)
                    .frame(width: geometry.size.width, height: geometry.size.width * appState.aspectRatio)
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
}

struct PreviewAreaView_Previews: PreviewProvider {
    static var previews: some View {
        let scene = SCNScene()
        let box = SCNBox(width: 0.1, height: 0.2, length: 0.05, chamferRadius: 0.01)
        let boxNode = SCNNode(geometry: box)
        scene.rootNode.addChildNode(boxNode)
        
        return PreviewAreaView(scene: scene, appState: AppState(), imagePickerManager: ImagePickerManager())
    }
}
