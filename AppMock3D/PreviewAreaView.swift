import SwiftUI
import SceneKit
import UIKit
import os
import Darwin

// MARK: - PreferenceKey
struct PreviewFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct PreviewAreaView: View {
    @Binding var currentScene: SCNScene
    @ObservedObject var appState: AppState
    @ObservedObject var imagePickerManager: ImagePickerManager
    // アピアアニメーション中は AppState 反映を一時停止するためのフラグ
    @State private var isAppearing: Bool = false
    // Hold initial transforms (per component)
    @State private var initialModelPosition: SCNVector3?
    @State private var initialModelScale: SCNVector3?
    @State private var initialModelEuler: SCNVector3?
    @State private var initialCameraTransform: SCNMatrix4?
    // Path to the target node (name sequence from root). Points to the "container" node to be manipulated, not the geometry.
    @State private var targetNodePath: [String] = []
    // Added: Notify parent of current scene updates
    var onSceneUpdated: ((SCNScene) -> Void)? = nil
    // Added: Notify parent of camera posture updates
    var onCameraUpdated: ((SCNMatrix4) -> Void)? = nil
    // Added: Callback to receive snapshot requests
    var onSnapshotRequested: ((UIImage?) -> Void)? = nil
    // Added: Trigger for snapshot request
    @Binding var shouldTakeSnapshot: Bool

    
    init(currentScene: Binding<SCNScene>, appState: AppState, imagePickerManager: ImagePickerManager, shouldTakeSnapshot: Binding<Bool>, onSceneUpdated: ((SCNScene) -> Void)? = nil, onCameraUpdated: ((SCNMatrix4) -> Void)? = nil, onSnapshotRequested: ((UIImage?) -> Void)? = nil) {
        self._currentScene = currentScene
        self.appState = appState
        self.imagePickerManager = imagePickerManager
        self._shouldTakeSnapshot = shouldTakeSnapshot
        self.onSceneUpdated = onSceneUpdated
        self.onCameraUpdated = onCameraUpdated
        self.onSnapshotRequested = onSnapshotRequested
    }
    
    private func startInitialAnimation() {
        // アニメーション期間中は applyAppStateTransform による上書きを抑止
        isAppearing = true
        // アニメ対象のノードを安全に取得（なければ作る）
        let target: SCNNode = ensureManipulationRoot()
        animateNodeAppearance(target)
        // アニメーション終了後にフラグを戻す（duration と同等の 1.0s + 小さな猶予）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            isAppearing = false
        }
    }
    
    private func findFirstGeometryNode(in root: SCNNode) -> SCNNode? {
        if root.geometry != nil {
            return root
        }
        for child in root.childNodes {
            if let found = findFirstGeometryNode(in: child) {
                return found
            }
        }
        return nil
    }
    
    private func animateNodeAppearance(_ node: SCNNode) {
        // Set initial state (scale: 0.3, rotation: Y = pi - 90 degrees)
        node.scale = SCNVector3(0.3, 0.3, 0.3)
        node.eulerAngles = SCNVector3(0, Float.pi - Float.pi/2, 0) // start at 90° towards the final pi orientation
        
        // Animate over 1 second (scale: defaultScale, rotation: Y = pi)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        
        node.scale = AppState.defaultScale
        node.eulerAngles = SCNVector3(0, Float.pi, 0)
        
        SCNTransaction.commit()
    }
    
    // Ensure there are named lights in the scene used by lighting controls.
    // Creates a key directional light ("mainLight") and a soft omni fill ("fillLight") if missing.
    private func ensureDefaultLights() {
        // If a main light does not exist, create one
        if currentScene.rootNode.childNode(withName: "mainLight", recursively: true) == nil {
            let mainLight = SCNLight()
            mainLight.type = .directional
            mainLight.intensity = 450
            mainLight.temperature = 6500
            mainLight.castsShadow = true
            mainLight.shadowMode = .deferred
            mainLight.shadowRadius = 8
            mainLight.shadowColor = UIColor.black.withAlphaComponent(0.5)

            let mainNode = SCNNode()
            mainNode.name = "mainLight"
            mainNode.light = mainLight
            // Default position/direction roughly from front-top-right
            mainNode.position = SCNVector3(4, 6, 6)
            mainNode.eulerAngles = SCNVector3(-Float.pi/4, -Float.pi/6, 0)
            currentScene.rootNode.addChildNode(mainNode)
        }

        // If a fill light does not exist, create one
        if currentScene.rootNode.childNode(withName: "fillLight", recursively: true) == nil {
            let fillLight = SCNLight()
            fillLight.type = .omni
            fillLight.intensity = 100
            fillLight.temperature = 6500
            fillLight.castsShadow = false

            let fillNode = SCNNode()
            fillNode.name = "fillLight"
            fillNode.light = fillLight
            fillNode.position = SCNVector3(-3, 2.5, 4.5)
            fillNode.eulerAngles = SCNVector3(-Float.pi/8, Float.pi/9, 0)
            currentScene.rootNode.addChildNode(fillNode)
        }

        // Ensure some environment lighting to prevent pitch black in PBR
        if currentScene.lightingEnvironment.contents == nil {
            // Use a neutral color as a simple environment; app may later set a cube map
            currentScene.lightingEnvironment.intensity = 1.0
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            MainContentView(
                currentScene: currentScene,
                appState: appState,
                imagePickerManager: imagePickerManager,
                shouldTakeSnapshot: $shouldTakeSnapshot,
                onCameraUpdated: onCameraUpdated,
                onSnapshotRequested: onSnapshotRequested,
                geometry: geometry
            )
        }
        .previewModifiers(
            appState: appState,
            imagePickerManager: imagePickerManager,
            shouldTakeSnapshot: shouldTakeSnapshot,
            updateSceneWithImage: updateSceneWithImage,
            updateSceneBackground: updateSceneBackground,
            applyLightingPreset: applyLightingPreset,
            applyLightingPosition: applyLightingPosition,
            resetSceneTransform: resetSceneTransform,
            applyAppStateTransform: applyAppStateTransform,
            onSceneUpdated: onSceneUpdated,
            onCameraUpdated: onCameraUpdated,
            currentScene: currentScene,
            captureInitialTransforms: captureInitialTransforms
        )
        .onAppear {
            // Start the animation when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                startInitialAnimation()
            }
        }
        // 端末切替完了トークンの変化を監視し、シーン差し替え後に必ずアニメーションを開始
        .onChange(of: appState.deviceReloadToken) { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                startInitialAnimation()
            }
        }
        .onChange(of: currentScene) { _, newScene in
            // When scene changes (e.g., device change), reapply background settings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let geometry = UIApplication.shared.windows.first?.bounds.size {
                    updateSceneBackground(appState.settings, size: CGSize(width: geometry.width, height: geometry.height))
                } else {
                    // Fallback size
                    updateSceneBackground(appState.settings, size: CGSize(width: 375, height: 667))
                }
            }
        }
        // Keep state stable; state is bound to upstream scene via @Binding
    }
}

// MARK: - MainContentView
private struct MainContentView: View {
    let currentScene: SCNScene
    let appState: AppState
    let imagePickerManager: ImagePickerManager
    @Binding var shouldTakeSnapshot: Bool
    let onCameraUpdated: ((SCNMatrix4) -> Void)?
    let onSnapshotRequested: ((UIImage?) -> Void)?
    let geometry: GeometryProxy
    
    var body: some View {
        ContentLayout(
            currentScene: currentScene,
            appState: appState,
            imagePickerManager: imagePickerManager,
            shouldTakeSnapshot: $shouldTakeSnapshot,
            onCameraUpdated: onCameraUpdated,
            onSnapshotRequested: onSnapshotRequested,
            geometry: geometry
        )
    }
}

// MARK: - ContentLayout
private struct ContentLayout: View {
    let currentScene: SCNScene
    let appState: AppState
    let imagePickerManager: ImagePickerManager
    @Binding var shouldTakeSnapshot: Bool
    let onCameraUpdated: ((SCNMatrix4) -> Void)?
    let onSnapshotRequested: ((UIImage?) -> Void)?
    let geometry: GeometryProxy
    
    private var maxAllowedHeight: CGFloat { 
        // Leave space for navigation and UI elements (approximately 200pt total)
        geometry.size.height - 200
    }
    
private var previewDimensions: (width: CGFloat, height: CGFloat) {
        let aspectRatio = appState.aspectRatio
        // Account for horizontal padding (12pt on each side = 24pt total)
        let availableWidth = geometry.size.width - 24
        let calculatedHeight = availableWidth / aspectRatio
        
        if calculatedHeight <= maxAllowedHeight {
            // Height fits, use available width
            return (availableWidth, calculatedHeight)
        } else {
            // Height overflows, adjust width to maintain aspect ratio
            let constrainedHeight = maxAllowedHeight
            let constrainedWidth = constrainedHeight * aspectRatio
            return (constrainedWidth, constrainedHeight)
        }
    }
    
    private var previewWidth: CGFloat { previewDimensions.width }
    private var previewHeight: CGFloat { previewDimensions.height }
    private var previewSize: CGSize { CGSize(width: previewWidth, height: previewHeight) }
    
var body: some View {
        ZStack {
            // Center the preview explicitly
            SceneView(
                currentScene: currentScene,
                appState: appState,
                shouldTakeSnapshot: $shouldTakeSnapshot,
                onCameraUpdated: onCameraUpdated,
                onSnapshotRequested: onSnapshotRequested,
                previewSize: previewSize,
                previewWidth: previewWidth,
                previewHeight: previewHeight
            )
        }
.frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 12)
    }
}

// MARK: - Component Views
private struct SceneView: View {
    let currentScene: SCNScene
    let appState: AppState
    @Binding var shouldTakeSnapshot: Bool
    let onCameraUpdated: ((SCNMatrix4) -> Void)?
    let onSnapshotRequested: ((UIImage?) -> Void)?
    let previewSize: CGSize
    let previewWidth: CGFloat
    let previewHeight: CGFloat
    
    var body: some View {
        ZStack {
            if appState.settings.backgroundColor == .transparent {
                CheckerboardBackground(lightColor: Color(white: 0.92),
                                       darkColor: Color(white: 0.82),
                                       squareSize: 12)
                    .frame(width: previewWidth, height: previewHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .allowsHitTesting(false)
            }
            SnapshotHostingView(
                scene: currentScene,
                previewSize: CGSize(width: previewWidth, height: previewHeight),
                shouldTakeSnapshot: $shouldTakeSnapshot,
                onCameraUpdate: { transform in
                    onCameraUpdated?(transform)
                },
                onSnapshotRequested: onSnapshotRequested,
                appState: appState
            )
        }
        .frame(width: previewWidth, height: previewHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(PreferenceBackground())
// .overlay(
        //     RoundedRectangle(cornerRadius: 10, style: .continuous)
        //         .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
        // )
        .clipped()
        .shadow(color: .black.opacity(0.3), radius: 14, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.3), value: currentScene.rootNode.childNodes.count)
        .overlay(alignment: .center) {
            if appState.isGridVisible {
                PreviewAreaView.GridOverlayView()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
    }
}

private struct PreferenceBackground: View {
    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: PreviewFramePreferenceKey.self,
                    value: proxy.frame(in: .global)
                )
        }
    }
}


// MARK: - ViewModifier Extension
extension View {
    func previewModifiers(
        appState: AppState,
        imagePickerManager: ImagePickerManager,
        shouldTakeSnapshot: Bool,
        updateSceneWithImage: @escaping (UIImage?, CGSize) -> Void,
        updateSceneBackground: @escaping (AppSettings, CGSize) -> Void,
        applyLightingPreset: @escaping (AppState.LightingPreset) -> Void,
        applyLightingPosition: @escaping (AppState.LightingPosition) -> Void,
        resetSceneTransform: @escaping () -> Void,
        applyAppStateTransform: @escaping () -> Void,
        onSceneUpdated: ((SCNScene) -> Void)?,
        onCameraUpdated: ((SCNMatrix4) -> Void)?,
        currentScene: SCNScene,
        captureInitialTransforms: @escaping () -> Void
    ) -> some View {
        self.modifier(
            PreviewModifiersViewModifier(
                appState: appState,
                imagePickerManager: imagePickerManager,
                shouldTakeSnapshot: shouldTakeSnapshot,
                updateSceneWithImage: updateSceneWithImage,
                updateSceneBackground: updateSceneBackground,
                applyLightingPreset: applyLightingPreset,
                applyLightingPosition: applyLightingPosition,
                resetSceneTransform: resetSceneTransform,
                applyAppStateTransform: applyAppStateTransform,
                onSceneUpdated: onSceneUpdated,
                onCameraUpdated: onCameraUpdated,
                currentScene: currentScene,
                captureInitialTransforms: captureInitialTransforms
            )
        )
    }
}

private struct PreviewModifiersViewModifier: ViewModifier {
    let appState: AppState
    let imagePickerManager: ImagePickerManager
    let shouldTakeSnapshot: Bool
    let updateSceneWithImage: (UIImage?, CGSize) -> Void
    let updateSceneBackground: (AppSettings, CGSize) -> Void
    let applyLightingPreset: (AppState.LightingPreset) -> Void
    let applyLightingPosition: (AppState.LightingPosition) -> Void
    let resetSceneTransform: () -> Void
    let applyAppStateTransform: () -> Void
    let onSceneUpdated: ((SCNScene) -> Void)?
    let onCameraUpdated: ((SCNMatrix4) -> Void)?
    let currentScene: SCNScene
    let captureInitialTransforms: () -> Void
    
    // Local helper: ensure lights exist in the provided scene
    private func ensureDefaultLights(in scene: SCNScene) {
        if scene.rootNode.childNode(withName: "mainLight", recursively: true) == nil {
            let mainLight = SCNLight()
            mainLight.type = .directional
            mainLight.intensity = 450
            mainLight.temperature = 6500
            mainLight.castsShadow = true
            mainLight.shadowMode = .deferred
            mainLight.shadowRadius = 8
            mainLight.shadowColor = UIColor.black.withAlphaComponent(0.5)

            let mainNode = SCNNode()
            mainNode.name = "mainLight"
            mainNode.light = mainLight
            mainNode.position = SCNVector3(4, 6, 6)
            mainNode.eulerAngles = SCNVector3(-Float.pi/4, -Float.pi/6, 0)
            scene.rootNode.addChildNode(mainNode)
        }
        if scene.rootNode.childNode(withName: "fillLight", recursively: true) == nil {
            let fillLight = SCNLight()
            fillLight.type = .omni
            fillLight.intensity = 100
            fillLight.temperature = 6500
            fillLight.castsShadow = false

            let fillNode = SCNNode()
            fillNode.name = "fillLight"
            fillNode.light = fillLight
            fillNode.position = SCNVector3(-3, 2.5, 4.5)
            fillNode.eulerAngles = SCNVector3(-Float.pi/8, Float.pi/9, 0)
            scene.rootNode.addChildNode(fillNode)
        }
        if scene.lightingEnvironment.contents == nil {
            scene.lightingEnvironment.intensity = 1.0
        }
    }
    
    func body(content: Content) -> some View {
        // Break down complex expressions to help the compiler
        let positionKey = appState.objectPosition.x + appState.objectPosition.y + appState.objectPosition.z
        let eulerKey = appState.objectEulerAngles.x + appState.objectEulerAngles.y + appState.objectEulerAngles.z
        let scaleKey = appState.objectScale.x + appState.objectScale.y + appState.objectScale.z

        return content
            .onChange(of: imagePickerManager.selectedImage) { _, newImage in
                updateSceneWithImage(newImage, CGSize(width: 375, height: 667))
            }
            .onChange(of: appState.settings) { _, newSettings in
                updateSceneBackground(newSettings, CGSize(width: 375, height: 667))
            }
            .onChange(of: appState.lightingPreset) { _, preset in
                applyLightingPreset(preset)
            }
            .onChange(of: appState.lightingPosition) { _, newPos in
                applyLightingPosition(newPos)
            }
            .onChange(of: appState.resetTransformToggle) { _ in
                resetSceneTransform()
            }
            .onChange(of: positionKey) { _, _ in
                applyAppStateTransform()
            }
            .onChange(of: eulerKey) { _, _ in
                applyAppStateTransform()
            }
            .onChange(of: scaleKey) { _, _ in
                applyAppStateTransform()
            }
            .onAppear {
                // Ensure the scene has default lights so lighting controls work and the model is not black
                ensureDefaultLights(in: currentScene)
                captureInitialTransforms()
                applyAppStateTransform()
                // Apply initial lighting position
                applyLightingPosition(appState.lightingPosition)
                // Apply initial background settings
                updateSceneBackground(appState.settings, CGSize(width: 375, height: 667))
                onSceneUpdated?(currentScene)
                if let pov = currentScene.rootNode.childNode(withName: "camera", recursively: true) {
                    onCameraUpdated?(pov.transform)
                }
            }
    }
}

extension PreviewAreaView {
    
    // MARK: - Apply Lighting
    private func applyLightingPreset(_ preset: AppState.LightingPreset) {
        // Get existing lights
        let main = currentScene.rootNode.childNode(withName: "mainLight", recursively: true)?.light
        let fill = currentScene.rootNode.childNode(withName: "fillLight", recursively: true)?.light
        
        switch preset {
        case .neutral:
            main?.intensity = 480
            currentScene.lightingEnvironment.intensity = 1.0
            fill?.intensity = 100
            main?.temperature = 6500 // Daylight
            fill?.temperature = 6500
        case .warm:
            main?.intensity = 520
            currentScene.lightingEnvironment.intensity = 1.5
            fill?.intensity = 110
            main?.temperature = 4000
            fill?.temperature = 4500
        case .cool:
            main?.intensity = 450
            currentScene.lightingEnvironment.intensity = 0.9
            fill?.intensity = 95
            main?.temperature = 8500
            fill?.temperature = 8000
        }

        // Adjust the fill light's attenuation to create a diffuse effect like a large light source
        if let fillNode = currentScene.rootNode.childNode(withName: "fillLight", recursively: true),
           let fillLight = fillNode.light {
            fillLight.attenuationStartDistance = 8.0
            fillLight.attenuationEndDistance = 22.0
            fillLight.attenuationFalloffExponent = 1.0
        }
    }

    // MARK: - Apply Lighting Position (1-10)
    private func applyLightingPosition(_ pos: AppState.LightingPosition) {
        guard
            let mainNode = currentScene.rootNode.childNode(withName: "mainLight", recursively: true),
            let mainLight = mainNode.light
        else { return }
        // Adjust the fill light's direction as a supplement
        let fillNode = currentScene.rootNode.childNode(withName: "fillLight", recursively: true)
        let fillLight = fillNode?.light

        // Helper: Fill light attenuation (light source size)
        func setFillAttenuation(start: CGFloat, end: CGFloat, falloff: CGFloat) {
            fillLight?.attenuationStartDistance = start
            fillLight?.attenuationEndDistance = end
            fillLight?.attenuationFalloffExponent = falloff
        }

        // Base light intensity (can be further weakened by presets)
        // Fine-tuned by position pattern
        var mainIntensity: CGFloat = 420
        var fillIntensity: CGFloat = 90
        
        // Set a consistent, brighter environment for all positions
        currentScene.lightingEnvironment.intensity = 1.5

        switch pos {
        case .one:
            // Soft diagonal light from the top right front
            mainNode.position = SCNVector3(x: Float(4.0), y: Float(6.0), z: Float(6.0))
            mainNode.eulerAngles = SCNVector3(x: -Float.pi/4, y: -Float.pi/6, z: 0)
            fillNode?.position = SCNVector3(x: Float(-3.0), y: Float(2.5), z: Float(4.5))
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/8, y: Float.pi/9, z: 0)
            setFillAttenuation(start: 10, end: 26, falloff: 1.0)
            mainIntensity = 420; fillIntensity = 90
        case .two:
            // Top light from the top left, slightly behind
            mainNode.position = SCNVector3(x: Float(-6.5), y: Float(7.0), z: Float(1.5))
            mainNode.eulerAngles = SCNVector3(x: -Float.pi/3.8, y: Float.pi/7, z: 0)
            fillNode?.position = SCNVector3(x: Float(3.0), y: Float(2.0), z: Float(5.2))
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/12, y: -Float.pi/14, z: 0)
            setFillAttenuation(start: 11, end: 28, falloff: 1.0)
            mainIntensity = 430; fillIntensity = 95
        case .three:
            // Uplift from the bottom front
            mainNode.position = SCNVector3(x: Float(0.0), y: Float(-2.2), z: Float(6.8))
            mainNode.eulerAngles = SCNVector3(x: Float.pi/9, y: 0, z: 0)
            fillNode?.position = SCNVector3(x: Float(2.0), y: Float(4.2), z: Float(4.2))
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/6, y: -Float.pi/12, z: 0)
            setFillAttenuation(start: 9, end: 24, falloff: 1.0)
            mainIntensity = 410; fillIntensity = 100
        case .four:
            // Backlight from the top rear
            mainNode.position = SCNVector3(x: Float(0.0), y: Float(7.5), z: Float(-4.5))
            mainNode.eulerAngles = SCNVector3(x: -Float.pi/2.6, y: 0, z: 0)
            fillNode?.position = SCNVector3(x: Float(0.0), y: Float(2.0), z: Float(6.2))
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/10, y: 0, z: 0)
            setFillAttenuation(start: 12, end: 30, falloff: 1.0)
            mainIntensity = 400; fillIntensity = 85
        case .five:
            // Sidelight from the right
            mainNode.position = SCNVector3(x: Float(7.0), y: Float(1.5), z: Float(3.5))
            mainNode.eulerAngles = SCNVector3(x: -Float.pi/10, y: -Float.pi/3.2, z: 0)
            fillNode?.position = SCNVector3(x: Float(-2.5), y: Float(3.5), z: Float(5.0))
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/10, y: Float.pi/10, z: 0)
            setFillAttenuation(start: 10, end: 26, falloff: 1.1)
            mainIntensity = 430; fillIntensity = 95
        case .six:
            // Left side light + slightly top
            mainNode.position = SCNVector3(x: Float(-7.0), y: Float(2.5), z: Float(3.0))
            mainNode.eulerAngles = SCNVector3(x: -Float.pi/8, y: Float.pi/3.4, z: 0)
            fillNode?.position = SCNVector3(x: Float(2.2), y: Float(3.2), z: Float(5.4))
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/11, y: -Float.pi/10, z: 0)
            setFillAttenuation(start: 11, end: 27, falloff: 1.1)
            mainIntensity = 420; fillIntensity = 100
        case .seven:
            // Low position from the bottom rear
            mainNode.position = SCNVector3(x: Float(0.0), y: Float(-3.5), z: Float(-2.0))
            mainNode.eulerAngles = SCNVector3(x: Float.pi/2.8, y: 0, z: 0)
            fillNode?.position = SCNVector3(x: Float(1.0), y: Float(3.8), z: Float(5.0))
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/8, y: -Float.pi/14, z: 0)
            setFillAttenuation(start: 12, end: 32, falloff: 1.0)
            mainIntensity = 380; fillIntensity = 90
        case .eight:
            // High-key from the top right front
            mainNode.position = SCNVector3(x: Float(5.5), y: Float(7.0), z: Float(6.5))
            mainNode.eulerAngles = SCNVector3(x: -Float.pi/3.8, y: -Float.pi/7, z: 0)
            fillNode?.position = SCNVector3(x: Float(-2.0), y: Float(1.8), z: Float(4.8))
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/12, y: Float.pi/9, z: 0)
            setFillAttenuation(start: 13, end: 34, falloff: 1.0)
            mainIntensity = 450; fillIntensity = 100
        case .nine:
            // Low-key from the top left front
            mainNode.position = SCNVector3(x: Float(-5.5), y: Float(6.0), z: Float(5.5))
            mainNode.eulerAngles = SCNVector3(x: -Float.pi/4.5, y: Float.pi/8, z: 0)
            fillNode?.position = SCNVector3(x: Float(2.5), y: Float(2.0), z: Float(5.5))
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/10, y: -Float.pi/11, z: 0)
            setFillAttenuation(start: 10, end: 28, falloff: 1.2)
            mainIntensity = 410; fillIntensity = 95
        case .ten:
            // Diffuse from the top front, slightly distant
            mainNode.position = SCNVector3(x: Float(0.0), y: Float(9.0), z: Float(8.5))
            mainNode.eulerAngles = SCNVector3(x: -Float.pi/3.2, y: 0, z: 0)
            fillNode?.position = SCNVector3(x: Float(0.0), y: Float(2.2), z: Float(6.8))
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/9, y: 0, z: 0)
            setFillAttenuation(start: 14, end: 36, falloff: 1.0)
            mainIntensity = 440; fillIntensity = 105
        }

        // Apply intensity (fine-tuned on the position side). Note that this can be overwritten by the preset on the last layer.
        mainLight.intensity = mainIntensity
        fillLight?.intensity = fillIntensity
    }
    
    // MARK: - Reset Transform (to 0/1/0 for AppState values)
    private func resetSceneTransform() {
        // Reset AppState values with animation
        withAnimation(.easeIn(duration: 0.7)) {
            appState.resetObjectTransformState()
        }
    }
    
    
    
    
    
    
    
    // Added: Reset all possible nodes
    private func resetAllPossibleNodes() {
        var allNodes: [SCNNode] = []
        collectAllNodes(from: currentScene.rootNode, into: &allNodes)
        
        for node in allNodes {
            let name = node.name?.lowercased() ?? ""
            // Reset nodes that are not cameras or lights and have geometry or specific names
            if !name.contains("camera") && !name.contains("light") {
                if node.geometry != nil || name.contains("model") || name.contains("iphone") {
                    print("[DEBUG] Resetting node: \(node.name ?? "unnamed") - pos=\(node.position), euler=\(node.eulerAngles), scale=\(node.scale)")
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.3
                    node.position = SCNVector3(0, 0, 0)
                    // Reset to baseline facing: Y = pi (180°)
                    node.eulerAngles = SCNVector3(0, Float.pi, 0)  
                    node.scale = AppState.defaultScale
                    SCNTransaction.commit()
                }
            }
        }
    }
    
    

    /// Depth-first search of the tree to return the first node with geometry
    private func firstGeometryNode(in root: SCNNode) -> SCNNode? {
        if root.geometry != nil {
            return root
        }
        for child in root.childNodes {
            if let found = firstGeometryNode(in: child) {
                return found
            }
        }
        return nil
    }

    /// Build a "name path" to the node (root -> child.name...)
    private func buildNamePath(for node: SCNNode) -> [String] {
        var path: [String] = []
        var current: SCNNode? = node
        while let n = current, let name = n.name {
            path.insert(name, at: 0)
            current = n.parent
            if current?.parent == nil { // Stop when the direct child of the rootNode is reached
                break
            }
        }
        return path
    }

    /// Traverse and get a node from the name path
    private func node(from root: SCNNode, by path: [String]) -> SCNNode? {
        // If empty or ["root"], return root (avoiding this as it's meaningless to have only root in the log)
        if path.isEmpty || (path.count == 1 && path.first?.lowercased() == "root") {
            return nil
        }
        var current: SCNNode? = root
        for segment in path {
            // Skip if the first segment is "root"
            if segment.lowercased() == "root" { continue }
            current = current?.childNode(withName: segment, recursively: false)
            if current == nil { break }
        }
        return current
    }

    /// Estimate and return a node that appears to be the iPhone body
    private func findIPhoneBodyNode(from root: SCNNode) -> SCNNode? {
        var all: [SCNNode] = []
        collectAllNodes(from: root, into: &all)

        // 1) Name heuristics (contains in lowercase)
        let keywords = ["iphone", "device", "phone", "body", "model"]
        if let nodeByName = all.first(where: { node in
            let name = node.name?.lowercased() ?? ""
            return node.geometry != nil && keywords.contains(where: { name.contains($0) })
        }) {
            return nodeByName
        }

        // 2) The one with the largest geometry size (number of vertices/faces)
        let nodeByGeometrySize = all
            .filter { $0.geometry != nil }
            .max(by: { lhs, rhs in
                geometryWeight(lhs.geometry!) < geometryWeight(rhs.geometry!)
            })
        if let candidate = nodeByGeometrySize {
            return candidate
        }

        // 3) If not found, return nil
        return nil
    }

    /// Recursively collect all nodes
    private func collectAllNodes(from node: SCNNode, into array: inout [SCNNode]) {
        array.append(node)
        for child in node.childNodes {
            collectAllNodes(from: child, into: &array)
        }
    }

    /// Estimate and return a "container" node suitable for manipulation
    /// 1) Find the node with the largest geometry
    /// 2) Go up its parent direction and prioritize the first found "parent without geometry" (group/container)
    /// 3) If not found, adopt the largest geometry node itself
    private func findManipulableContainerNode(from root: SCNNode) -> SCNNode? {
        var all: [SCNNode] = []
        collectAllNodes(from: root, into: &all)

        // Largest geometry node
        let biggestGeoNode = all
            .filter { $0.geometry != nil }
            .max(by: { geometryWeight($0.geometry!) < geometryWeight($1.geometry!) })

        guard let node = biggestGeoNode else {
            // Fallback: first geometry
            return firstGeometryNode(in: root)
        }

        // Go up to the parent and prioritize a "container suitable for manipulation"
        // Heuristics:
        //  - Prioritize parents whose names contain Container/Rotation/Transform/Group/Root
        //  - If none, prioritize parents with non-unitary scale / non-zero rotation / non-zero position (likely to have user operations)
        //  - Finally, parents with "no geometry"
        var best: SCNNode = node
        var current: SCNNode? = node
        let nameHints = ["container", "rotation", "transform", "group", "root"]
        while let parent = current?.parent, parent !== root {
            let lname = parent.name?.lowercased() ?? ""
            let hasNameHint = nameHints.first(where: { lname.contains($0) }) != nil
            // Compare SCNVector3 by each component (with a threshold for floating point numbers)
            func isNonUnit(_ v: SCNVector3) -> Bool {
                let eps: Float = 1e-4
                return abs(v.x - Float(1)) > eps || abs(v.y - Float(1)) > eps || abs(v.z - Float(1)) > eps
            }
            func isNonZero(_ v: SCNVector3) -> Bool {
                let eps: Float = 1e-4
                return abs(v.x) > eps || abs(v.y) > eps || abs(v.z) > eps
            }
            let nonUnitScale = isNonUnit(parent.scale)
            let nonZeroRot   = isNonZero(parent.eulerAngles)
            let nonZeroPos   = isNonZero(parent.position)

            if hasNameHint || nonUnitScale || nonZeroRot || nonZeroPos || parent.geometry == nil {
                best = parent
            }
            current = parent
        }
        return best
    }

    /// Simple evaluation of geometry size
    private func geometryWeight(_ geom: SCNGeometry) -> Int {
        // Calculate a simple score by summing the number of faces and vertices
        let elements: [SCNGeometryElement] = geom.elements
        let faces = elements.reduce(0) { $0 + $1.primitiveCount }
        
        let verticesSource = geom.sources(for: .vertex).first
        let vertices = verticesSource?.vectorCount ?? 0
        
        return faces * 4 + vertices
    }

    // MARK: - Capture Initial Transform (with debug logs)
    private func captureInitialTransforms() {
        // First, estimate the "manipulable container" from the top of the largest geometry
        var container = findManipulableContainerNode(from: currentScene.rootNode)
            ?? findIPhoneBodyNode(from: currentScene.rootNode)
            ?? firstGeometryNode(in: currentScene.rootNode)

        // If a path cannot be created because there are only unnamed nodes, prepare a "manipulationRoot" directly under the root and attach them to it (only for the first time)
        if container == nil {
            container = currentScene.rootNode.childNode(withName: "manipulationRoot", recursively: false)
            if container == nil {
                let newRoot = SCNNode()
                newRoot.name = "manipulationRoot"
                currentScene.rootNode.addChildNode(newRoot)

                let childrenToMove = currentScene.rootNode.childNodes.filter {
                    let lname = ($0.name ?? "").lowercased()
                    return lname != "manipulationroot" && !lname.contains("light") && !lname.contains("camera")
                }
                
                for child in childrenToMove {
                    // Reparent while maintaining world coordinates
                    let worldTransform = child.worldTransform
                    child.removeFromParentNode()
                    newRoot.addChildNode(child)
                    child.transform = newRoot.convertTransform(worldTransform, from: nil)
                }
                container = newRoot
            }
        }

        if let containerNode = container {
            if let name = containerNode.name, !name.isEmpty {
                targetNodePath = buildNamePath(for: containerNode)
            } else {
                targetNodePath = []
            }
            initialModelPosition = containerNode.position
            initialModelScale    = containerNode.scale
            initialModelEuler    = containerNode.eulerAngles

            func v3(_ v: SCNVector3?) -> String {
                guard let v else { return "nil" }
                return String(format: "(%.4f, %.4f, %.4f)", v.x, v.y, v.z)
            }
            let pathStr = targetNodePath.joined(separator: "/")
            let posStr  = v3(initialModelPosition)
            let scaleStr = v3(initialModelScale)
            let eulerStr = v3(initialModelEuler)
            print("[Capture] path=\(pathStr) pos=\(posStr) scale=\(scaleStr) euler=\(eulerStr)")
        } else {
            targetNodePath = []
            initialModelPosition = nil
            initialModelScale    = nil
            initialModelEuler    = nil
            print("[Capture] target not found")
        }

        // Camera
        let cameraNode = currentScene.rootNode.childNode(withName: "camera", recursively: true)
        initialCameraTransform = cameraNode?.transform
    }
    
    private func updateSceneWithImage(_ image: UIImage?, size: CGSize) {
        guard let image = image else {
            // If the image is cleared, clear only the texture from the current scene
            appState.clearImageState()
            
            withAnimation(.easeInOut(duration: 0.3)) {
                // Clear the texture from the current scene (transform state is maintained)
                if let clearedScene = TextureManager.shared.clearTextureFromModel(currentScene) {
                    currentScene = clearedScene
                    updateSceneBackground(appState.settings, size: size)
                    print("[PreviewAreaView] Cleared texture while preserving all transforms")
                }
            }
            
            // Notify parent of the latest scene
            onSceneUpdated?(currentScene)
            return
        }
        
        // Check image validity
        guard image.size.width > 0 && image.size.height > 0 else {
            DispatchQueue.main.async {
                appState.setImageError("Invalid image. Please select another image.")
            }
            return
        }
        
        // Notify that processing has started
        DispatchQueue.main.async {
            appState.setImageProcessing(true)
        }
        
        // Apply texture asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
            // Check memory usage
            let memoryUsage = Self.getMemoryUsage()
            if memoryUsage > 0.8 { // If over 80%
                TextureManager.shared.clearCache()
            }
            
            // Execute texture application
            if let updatedScene = TextureManager.shared.applyTextureToModel(self.currentScene, image: image) {
                DispatchQueue.main.async {
                    // Set the scene with the current transform maintained
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.currentScene = updatedScene
                        self.updateSceneBackground(self.appState.settings, size: size)
                    }
                    
                    // Notify parent of the latest scene
                    self.onSceneUpdated?(updatedScene)
                    self.appState.setImageApplied(true)
                    self.appState.setImageProcessing(false)
                }
            } else {
                DispatchQueue.main.async {
                    appState.setImageError("Failed to apply texture. The screen may not be found in the 3D model.")
                }
            }
        }
    }
    
    // MARK: - Grid Overlay
    struct GridOverlayView: View {
        // Automatically adjusts to screen density and size, but basically draws lines at regular intervals vertically and horizontally
        var majorStep: Int = 4     // Number of divisions for thick lines (e.g., 4 divisions)
        var minorPerMajor: Int = 4 // Number of further divisions between each major (thin lines)
    
        var body: some View {
            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height
    
                // Calculation
                let majorColumns = CGFloat(majorStep)
                let majorRows = CGFloat(majorStep)
                let minorColumns = majorColumns * CGFloat(minorPerMajor)
                let minorRows = majorRows * CGFloat(minorPerMajor)
    
                ZStack {
                    // Minor grid (light)
                    Path { path in
                        // Vertical lines
                        for i in 1..<Int(minorColumns) {
                            let x = width * CGFloat(i) / minorColumns
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: height))
                        }
                        // Horizontal lines
                        for j in 1..<Int(minorRows) {
                            let y = height * CGFloat(j) / minorRows
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                    }
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
    
                    // Major grid (slightly stronger)
                    Path { path in
                        // Vertical lines
                        for i in 1..<Int(majorColumns) {
                            let x = width * CGFloat(i) / majorColumns
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: height))
                        }
                        // Horizontal lines
                        for j in 1..<Int(majorRows) {
                            let y = height * CGFloat(j) / majorRows
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                    }
                    .stroke(Color.white.opacity(0.35), lineWidth: 1.0)
    
                    // Emphasize the outer frame slightly
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                }
                .blendMode(.screen) // Make it easier to see on a dark background
            }
        }
    }

    private func updateSceneBackground(_ settings: AppSettings, size: CGSize) {
        switch settings.backgroundColor {
        case .solidColor:
            if let color = Color(hex: settings.solidColorValue) {
                currentScene.background.contents = UIColor(color)
            } else {
                currentScene.background.contents = UIColor.white
            }
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

    // MARK: - Coordinator
    class Coordinator: NSObject, SCNSceneRendererDelegate {
        var onCameraUpdate: ((SCNMatrix4) -> Void)?
        var onSnapshotRequested: ((UIImage?) -> Void)?
        var scnView: SCNView?
        var appState: AppState?

        init(onCameraUpdate: ((SCNMatrix4) -> Void)?, onSnapshotRequested: ((UIImage?) -> Void)?) {
            self.onCameraUpdate = onCameraUpdate
            self.onSnapshotRequested = onSnapshotRequested
            super.init()
        }
        
        // Set up object manipulation gestures
        func setupObjectManipulationGestures(for scnView: SCNView) {
            // Pan gesture
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
            panGesture.maximumNumberOfTouches = 2
            scnView.addGestureRecognizer(panGesture)
            
            // Pinch gesture
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
            scnView.addGestureRecognizer(pinchGesture)
        }
        
        @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
            guard let appState = appState else { return }
            
            let translation = gesture.translation(in: gesture.view)
            
            if gesture.state == .changed {
                switch gesture.numberOfTouches {
                case 1: // 1 finger: rotation
                    // Invert vertical rotation direction
                    let rotationX = -Float(translation.y) * 0.01
                    let rotationY = Float(translation.x) * 0.01
                    
                    let oldEuler = appState.objectEulerAngles
                    let newEulerX = oldEuler.x + rotationX
                    let newEulerY = oldEuler.y + rotationY
                    
                    // 60度の回転制限を適用（ラジアンに変換: 60度 = π/3）
                    let maxRotation: Float = Float.pi / 3.0 // 60度
                    let clampedEulerX = max(-maxRotation, min(maxRotation, newEulerX))
                    let clampedEulerY = max(-maxRotation, min(maxRotation, newEulerY))
                    
                    let newEuler = SCNVector3(clampedEulerX, clampedEulerY, oldEuler.z)
                    
                    appState.setObjectEuler(newEuler)
                    
                case 2: // 2 fingers: position movement
                    let moveX = Float(translation.x) * 0.005
                    // Keep original vertical direction for 2-finger translation
                    let moveY = Float(translation.y) * -0.005
                    
                    let oldPos = appState.objectPosition
                    let newPos = SCNVector3(oldPos.x + moveX, oldPos.y + moveY, oldPos.z)
                    
                    appState.setObjectPosition(newPos)
                    
                default:
                    break
                }
            }
            
            gesture.setTranslation(.zero, in: gesture.view)
        }
        
        @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
            guard let appState = appState else { return }
            
            let scale = Float(gesture.scale)
            
            if gesture.state == .changed {
                let oldScale = appState.objectScale
                let newScaleX = oldScale.x * scale
                let newScaleY = oldScale.y * scale
                let newScaleZ = oldScale.z * scale
                
                // Scale limit
                let minScale: Float = 0.5
                let maxScale: Float = 3.0
                let clampedScale = SCNVector3(
                    max(minScale, min(maxScale, newScaleX)),
                    max(minScale, min(maxScale, newScaleY)), 
                    max(minScale, min(maxScale, newScaleZ))
                )
                
                appState.setObjectScale(clampedScale)
            }
            
            gesture.scale = 1.0
        }

        func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
            // Get the camera's transform (posture) and notify
            if let pov = renderer.pointOfView {
                onCameraUpdate?(pov.transform)
            }
        }
        
        func takeSnapshot() {
            guard let scnView = scnView else {
                onSnapshotRequested?(nil)
                return
            }
            
            // Notify the latest camera transform before taking a snapshot
            if let pov = scnView.pointOfView {
                onCameraUpdate?(pov.transform)
            }
            
            DispatchQueue.main.async {
                let snapshot = scnView.snapshot()
                self.onSnapshotRequested?(snapshot)
            }
        }
    }
}

// MARK: - SnapshotHostingView (SCNView wrapper)
struct SnapshotHostingView: UIViewRepresentable {
    typealias UIViewType = SCNView

    var scene: SCNScene
    var previewSize: CGSize
    @Binding var shouldTakeSnapshot: Bool
    var onCameraUpdate: ((SCNMatrix4) -> Void)?
    var onSnapshotRequested: ((UIImage?) -> Void)?
    var appState: AppState

    func makeCoordinator() -> PreviewAreaView.Coordinator {
        PreviewAreaView.Coordinator(onCameraUpdate: onCameraUpdate, onSnapshotRequested: onSnapshotRequested)
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView(frame: CGRect(origin: .zero, size: previewSize))
        scnView.scene = scene
        scnView.backgroundColor = .clear
        scnView.allowsCameraControl = false
        // Fallback: enable default lighting to avoid completely dark scene when no lights exist
        scnView.autoenablesDefaultLighting = true
        scnView.isPlaying = true
        scnView.delegate = context.coordinator

        // Wire coordinator references
        context.coordinator.scnView = scnView
        context.coordinator.appState = appState
        context.coordinator.setupObjectManipulationGestures(for: scnView)

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // Keep scene in sync if it changed upstream
        if uiView.scene !== scene {
            uiView.scene = scene
        }

        // Ensure size matches the preview container
        let desired = CGRect(origin: .zero, size: previewSize)
        if uiView.frame.size != desired.size {
            uiView.frame = desired
        }

        // Forward updated appState reference
        context.coordinator.appState = appState

        // Snapshot trigger
        if shouldTakeSnapshot {
            context.coordinator.takeSnapshot()
            // Reset the trigger on the next runloop to avoid state mutation during update cycle
            DispatchQueue.main.async {
                self.shouldTakeSnapshot = false
            }
        }
    }
}

// MARK: - Memory Utility
extension PreviewAreaView {
    /// Returns the current app's memory usage as a fraction of total physical memory (0.0 ... 1.0).
    static func getMemoryUsage() -> Double {
        // Total physical memory
        let total = Double(ProcessInfo.processInfo.physicalMemory)

        // Get task (app) memory via mach task_info
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
            }
        }

        guard kerr == KERN_SUCCESS else { return 0.0 }

        // phys_footprint approximates the real memory used by the app
        let used = Double(info.phys_footprint)
        if total <= 0 { return 0.0 }
        return max(0.0, min(1.0, used / total))
    }
}

extension PreviewAreaView {
    // Apply the transform held in AppState to manipulationRoot
    private func applyAppStateTransform() {
        // アピアアニメーション中はスナップ上書きを避ける
        if isAppearing { return }
        // Get the root for manipulation (create if it doesn't exist)
        let root = ensureManipulationRoot()
        
        SCNTransaction.begin()
        root.position = appState.objectPosition
        // Apply baseline Y=pi so the model faces forward initially, while keeping appState at 0-based rotation
        root.eulerAngles = SCNVector3(
            appState.objectEulerAngles.x,
            appState.objectEulerAngles.y + Float.pi,
            appState.objectEulerAngles.z
        )
        root.scale = appState.objectScale
        SCNTransaction.commit()
    }
    
    // Returns manipulationRoot (if it doesn't exist, create it by hanging everything except lights/cameras)
    @discardableResult
    private func ensureManipulationRoot() -> SCNNode {
        if let node = currentScene.rootNode.childNode(withName: "manipulationRoot", recursively: false) {
            return node
        }
        // Create a new one and reparent everything except lights and cameras
        let newRoot = SCNNode()
        newRoot.name = "manipulationRoot"
        currentScene.rootNode.addChildNode(newRoot)

        // Scan the current direct children and move everything except lights/cameras
        let children = currentScene.rootNode.childNodes.filter {
            let lname = ($0.name ?? "").lowercased()
            return lname != "manipulationroot" && !lname.contains("light") && !lname.contains("camera")
        }
        
        for child in children {
            // Reparent while maintaining world coordinates
            let worldTransform = child.worldTransform
            child.removeFromParentNode()
            newRoot.addChildNode(child)
            child.transform = newRoot.convertTransform(worldTransform, from: nil)
        }
        return newRoot
    }
}

struct PreviewAreaView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewAreaViewWrapper()
    }
}

private struct PreviewAreaViewWrapper: View {
    @State private var shouldTakeSnapshot = false
    @State private var scene = SCNScene()
    @State private var didSetup = false
    
    var body: some View {
        // Setup a simple scene once for preview
        if !didSetup {
            let box = SCNBox(width: 0.1, height: 0.2, length: 0.05, chamferRadius: 0.01)
            let boxNode = SCNNode(geometry: box)
            scene.rootNode.addChildNode(boxNode)
            didSetup = true
        }
        
        return PreviewAreaView(currentScene: $scene, appState: AppState(), imagePickerManager: ImagePickerManager(), shouldTakeSnapshot: $shouldTakeSnapshot)
    }
}
