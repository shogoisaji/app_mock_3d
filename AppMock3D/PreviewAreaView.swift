import SwiftUI
import SceneKit

// MARK: - PreferenceKey
struct PreviewFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct PreviewAreaView: View {
    let originalScene: SCNScene
    @ObservedObject var appState: AppState
    @ObservedObject var imagePickerManager: ImagePickerManager
    @State private var currentScene: SCNScene
    // 初期トランスフォーム保持（コンポーネント別）
    @State private var initialModelPosition: SCNVector3?
    @State private var initialModelScale: SCNVector3?
    @State private var initialModelEuler: SCNVector3?
    @State private var initialCameraTransform: SCNMatrix4?
    // 操作対象ノードのパス（root からの名前列）。ジオメトリではなく「操作すべきコンテナ」ノードを指す
    @State private var targetNodePath: [String] = []
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
    
    private var previewWidth: CGFloat { geometry.size.width }
    private var previewHeight: CGFloat { geometry.size.width / appState.aspectRatio }
    private var previewSize: CGSize { CGSize(width: previewWidth, height: previewHeight) }
    
    var body: some View {
        ZStack {
            BackgroundOverlay()
            
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
            
            if imagePickerManager.selectedImage == nil && !appState.isImageProcessing {
                EmptyStateView()
            }
        }
    }
}

// MARK: - Component Views
private struct BackgroundOverlay: View {
    var body: some View {
        Color.black.opacity(0.5)
            .edgesIgnoringSafeArea(.all)
    }
}

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
        SnapshotHostingView(
            scene: currentScene,
            previewSize: previewSize,
            shouldTakeSnapshot: $shouldTakeSnapshot,
            onCameraUpdate: { transform in
                onCameraUpdated?(transform)
            },
            onSnapshotRequested: onSnapshotRequested
        )
        .frame(width: previewWidth, height: previewHeight)
        .background(PreferenceBackground())
        .border(Color.white, width: 2)
        .clipped()
        .animation(.easeInOut(duration: 0.3), value: currentScene)
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

private struct EmptyStateView: View {
    var body: some View {
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
    
    func body(content: Content) -> some View {
        content
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
            .onChange(of: appState.objectPosition.x + appState.objectPosition.y + appState.objectPosition.z) { _, _ in
                applyAppStateTransform()
            }
            .onChange(of: appState.objectEulerAngles.x + appState.objectEulerAngles.y + appState.objectEulerAngles.z) { _, _ in
                applyAppStateTransform()
            }
            .onChange(of: appState.objectScale.x + appState.objectScale.y + appState.objectScale.z) { _, _ in
                applyAppStateTransform()
            }
            .onAppear {
                captureInitialTransforms()
                applyAppStateTransform()
                onSceneUpdated?(currentScene)
                if let pov = currentScene.rootNode.childNode(withName: "camera", recursively: true) {
                    onCameraUpdated?(pov.transform)
                }
            }
    }
}

extension PreviewAreaView {
    
    // MARK: - ライティング適用
    private func applyLightingPreset(_ preset: AppState.LightingPreset) {
        // 既存ライトを取得
        let main = currentScene.rootNode.childNode(withName: "mainLight", recursively: true)?.light
        let ambient = currentScene.rootNode.childNode(withName: "ambientLight", recursively: true)?.light
        let fill = currentScene.rootNode.childNode(withName: "fillLight", recursively: true)?.light
        
        switch preset {
        case .neutral:
            main?.intensity = 480
            ambient?.intensity = 180
            fill?.intensity = 100
            main?.temperature = 6500 // デイライト
            fill?.temperature = 6500
        case .warm:
            main?.intensity = 520
            ambient?.intensity = 190
            fill?.intensity = 110
            main?.temperature = 4000
            fill?.temperature = 4500
        case .cool:
            main?.intensity = 450
            ambient?.intensity = 170
            fill?.intensity = 95
            main?.temperature = 8500
            fill?.temperature = 8000
        }

        // フィルライトの減衰を調整して「大きい光源」っぽい拡散感を出す
        if let fillNode = currentScene.rootNode.childNode(withName: "fillLight", recursively: true),
           let fillLight = fillNode.light {
            fillLight.attenuationStartDistance = 8.0
            fillLight.attenuationEndDistance = 22.0
            fillLight.attenuationFalloffExponent = 1.0
        }
    }

    // MARK: - ライティングポジション適用（1〜10）
    private func applyLightingPosition(_ pos: AppState.LightingPosition) {
        guard
            let mainNode = currentScene.rootNode.childNode(withName: "mainLight", recursively: true),
            let mainLight = mainNode.light
        else { return }
        // フィルライトは補助的に向きを合わせる
        let fillNode = currentScene.rootNode.childNode(withName: "fillLight", recursively: true)
        let fillLight = fillNode?.light

        // ヘルパ: フィルライトの減衰（光源サイズ感）
        func setFillAttenuation(start: CGFloat, end: CGFloat, falloff: CGFloat) {
            fillLight?.attenuationStartDistance = start
            fillLight?.attenuationEndDistance = end
            fillLight?.attenuationFalloffExponent = falloff
        }

        // ベースのかなり弱い光量（プリセットでさらに弱められる前提）
        // 位置パターン側でも微調整
        var mainIntensity: CGFloat = 420
        var fillIntensity: CGFloat = 90

        switch pos {
        case .one:
            // 右上前方からのやわらかい斜光
            mainNode.position = SCNVector3(x: 4.0, y: 6.0, z: 6.0)
            mainNode.eulerAngles = SCNVector3(x: -Float.pi/4, y: -Float.pi/6, z: 0)
            fillNode?.position = SCNVector3(x: -3.0, y: 2.5, z: 4.5)
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/8, y: Float.pi/9, z: 0)
            setFillAttenuation(start: 10, end: 26, falloff: 1.0)
            mainIntensity = 420; fillIntensity = 90
        case .two:
            // 左上やや後方のトップ
            mainNode.position = SCNVector3(x: -6.5, y: 7.0, z: 1.5)
            mainNode.eulerAngles = SCNVector3(x: -Float.pi/3.8, y: Float.pi/7, z: 0)
            fillNode?.position = SCNVector3(x: 3.0, y: 2.0, z: 5.2)
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/12, y: -Float.pi/14, z: 0)
            setFillAttenuation(start: 11, end: 28, falloff: 1.0)
            mainIntensity = 430; fillIntensity = 95
        case .three:
            // 下手前からの持ち上げ
            mainNode.position = SCNVector3(x: 0.0, y: -2.2, z: 6.8)
            mainNode.eulerAngles = SCNVector3(x: Float.pi/9, y: 0, z: 0)
            fillNode?.position = SCNVector3(x: 2.0, y: 4.2, z: 4.2)
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/6, y: -Float.pi/12, z: 0)
            setFillAttenuation(start: 9, end: 24, falloff: 1.0)
            mainIntensity = 410; fillIntensity = 100
        case .four:
            // 上後方のバックライト
            mainNode.position = SCNVector3(x: 0.0, y: 7.5, z: -4.5)
            mainNode.eulerAngles = SCNVector3(x: -Float.pi/2.6, y: 0, z: 0)
            fillNode?.position = SCNVector3(x: 0.0, y: 2.0, z: 6.2)
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/10, y: 0, z: 0)
            setFillAttenuation(start: 12, end: 30, falloff: 1.0)
            mainIntensity = 400; fillIntensity = 85
        case .five:
            // 右側面からのサイドライト
            mainNode.position = SCNVector3(x: 7.0, y: 1.5, z: 3.5)
            mainNode.eulerAngles = SCNVector3(x: -Float.pi/10, y: -Float.pi/3.2, z: 0)
            fillNode?.position = SCNVector3(x: -2.5, y: 3.5, z: 5.0)
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/10, y: Float.pi/10, z: 0)
            setFillAttenuation(start: 10, end: 26, falloff: 1.1)
            mainIntensity = 430; fillIntensity = 95
        case .six:
            // 左側面サイド＋ややトップ
            mainNode.position = SCNVector3(x: -7.0, y: 2.5, z: 3.0)
            mainNode.eulerAngles = SCNVector3(x: -Float.pi/8, y: Float.pi/3.4, z: 0)
            fillNode?.position = SCNVector3(x: 2.2, y: 3.2, z: 5.4)
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/11, y: -Float.pi/10, z: 0)
            setFillAttenuation(start: 11, end: 27, falloff: 1.1)
            mainIntensity = 420; fillIntensity = 100
        case .seven:
            // 下後方からのローポジション
            mainNode.position = SCNVector3(x: 0.0, y: -3.5, z: -2.0)
            mainNode.eulerAngles = SCNVector3(x: Float.pi/2.8, y: 0, z: 0)
            fillNode?.position = SCNVector3(x: 1.0, y: 3.8, z: 5.0)
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/8, y: -Float.pi/14, z: 0)
            setFillAttenuation(start: 12, end: 32, falloff: 1.0)
            mainIntensity = 380; fillIntensity = 90
        case .eight:
            // 右上前方のハイキー寄り
            mainNode.position = SCNVector3(x: 5.5, y: 7.0, z: 6.5)
            mainNode.eulerAngles = SCNVector3(x: -Float.pi/3.8, y: -Float.pi/7, z: 0)
            fillNode?.position = SCNVector3(x: -2.0, y: 1.8, z: 4.8)
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/12, y: Float.pi/9, z: 0)
            setFillAttenuation(start: 13, end: 34, falloff: 1.0)
            mainIntensity = 450; fillIntensity = 100
        case .nine:
            // 左上前方のローキー寄り
            mainNode.position = SCNVector3(x: -5.5, y: 6.0, z: 5.5)
            mainNode.eulerAngles = SCNVector3(x: -Float.pi/4.5, y: Float.pi/8, z: 0)
            fillNode?.position = SCNVector3(x: 2.5, y: 2.0, z: 5.5)
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/10, y: -Float.pi/11, z: 0)
            setFillAttenuation(start: 10, end: 28, falloff: 1.2)
            mainIntensity = 410; fillIntensity = 95
        case .ten:
            // 上方正面やや遠方からのディフューズ
            mainNode.position = SCNVector3(x: 0.0, y: 9.0, z: 8.5)
            mainNode.eulerAngles = SCNVector3(x: -Float.pi/3.2, y: 0, z: 0)
            fillNode?.position = SCNVector3(x: 0.0, y: 2.2, z: 6.8)
            fillNode?.eulerAngles = SCNVector3(x: -Float.pi/9, y: 0, z: 0)
            setFillAttenuation(start: 14, end: 36, falloff: 1.0)
            mainIntensity = 440; fillIntensity = 105
        }

        // 強度適用（ポジション側の微調整）。プリセットとは別レイヤーで最後に上書きされ得る点に注意。
        mainLight.intensity = mainIntensity
        fillLight?.intensity = fillIntensity
    }
    
    // MARK: - 変換のリセット（AppStateの保持値を0/1/0へ）
    private func resetSceneTransform() {
        // 状態を0/1/0へ戻し、反映は onChange ハンドラで行う
        appState.resetObjectTransformState()
    }

    /// ツリーを深さ優先で探索し、ジオメトリを持つ最初のノードを返す
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

    /// ノードへの「名前パス」を構築（root -> child.name...）
    private func buildNamePath(for node: SCNNode) -> [String] {
        var path: [String] = []
        var current: SCNNode? = node
        while let n = current, let name = n.name {
            path.insert(name, at: 0)
            current = n.parent
            if current?.parent == nil { // rootNode の直下に到達したら終了
                break
            }
        }
        return path
    }

    /// 名前パスからノードを辿って取得
    private func node(from root: SCNNode, by path: [String]) -> SCNNode? {
        // 空 or ["root"] の場合は root を返す（ログに root が出るだけで実質意味がないため回避する）
        if path.isEmpty || (path.count == 1 && path.first?.lowercased() == "root") {
            return nil
        }
        var current: SCNNode? = root
        for segment in path {
            // 最初のセグメントが "root" の場合はスキップ
            if segment.lowercased() == "root" { continue }
            current = current?.childNode(withName: segment, recursively: false)
            if current == nil { break }
        }
        return current
    }

    /// iPhone本体らしいノードを推定して返す
    private func findIPhoneBodyNode(from root: SCNNode) -> SCNNode? {
        var all: [SCNNode] = []
        collectAllNodes(from: root, into: &all)

        // 1) 名前ヒューリスティックス（小文字で含む）
        let keywords = ["iphone", "device", "phone", "body", "model"]
        if let nodeByName = all.first(where: { node in
            let name = node.name?.lowercased() ?? ""
            return node.geometry != nil && keywords.contains(where: { name.contains($0) })
        }) {
            return nodeByName
        }

        // 2) ジオメトリの規模（頂点数/面数）で最大のもの
        let nodeByGeometrySize = all
            .filter { $0.geometry != nil }
            .max(by: { lhs, rhs in
                geometryWeight(lhs.geometry!) < geometryWeight(rhs.geometry!)
            })
        if let candidate = nodeByGeometrySize {
            return candidate
        }

        // 3) 見つからない場合はnil
        return nil
    }

    /// 再帰的に全ノード収集
    private func collectAllNodes(from node: SCNNode, into array: inout [SCNNode]) {
        array.append(node)
        for child in node.childNodes {
            collectAllNodes(from: child, into: &array)
        }
    }

    /// 操作対象に適した「コンテナ」ノードを推定して返す
    /// 1) 最大ジオメトリを持つノードを見つける
    /// 2) その親方向に遡って、最初に見つかる「ジオメトリを持たない親」（グループ/コンテナ）を優先採用
    /// 3) 見つからなければ最大ジオメトリノード自身を採用
    private func findManipulableContainerNode(from root: SCNNode) -> SCNNode? {
        var all: [SCNNode] = []
        collectAllNodes(from: root, into: &all)

        // 最大ジオメトリノード
        let biggestGeoNode = all
            .filter { $0.geometry != nil }
            .max(by: { geometryWeight($0.geometry!) < geometryWeight($1.geometry!) })

        guard var node = biggestGeoNode else {
            // フォールバック: 最初のジオメトリ
            return firstGeometryNode(in: root)
        }

        // 親へ遡って「操作対象に適したコンテナ」を優先
        // ヒューリスティック:
        //  - 名前に Container/Rotation/Transform/Group/Root を含む親を優先
        //  - それが無ければ、非ユニタリスケール / 非ゼロ回転 / 非ゼロ位置を持つ親を優先（ユーザー操作が載っている可能性）
        //  - 最後に「ジオメトリ無し」の親
        var best: SCNNode = node
        var current: SCNNode? = node
        let nameHints = ["container", "rotation", "transform", "group", "root"]
        while let parent = current?.parent, parent !== root {
            let lname = parent.name?.lowercased() ?? ""
            let hasNameHint = nameHints.first(where: { lname.contains($0) }) != nil
            // SCNVector3 の比較は各成分で判定（浮動小数のため閾値付き）
            func isNonUnit(_ v: SCNVector3) -> Bool {
                let eps: Float = 1e-4
                return abs(v.x - 1) > eps || abs(v.y - 1) > eps || abs(v.z - 1) > eps
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

    /// ジオメトリ規模の簡易評価
    private func geometryWeight(_ geom: SCNGeometry) -> Int {
        // 面数と頂点数を合算して簡易スコアを算出
        let elements: [SCNGeometryElement] = geom.elements
        let faces = elements.reduce(0) { $0 + $1.primitiveCount }
        
        let verticesSource = geom.sources(for: .vertex).first
        let vertices = verticesSource?.vectorCount ?? 0
        
        return faces * 4 + vertices
    }

    // MARK: - 初期Transformのキャプチャ（デバッグログ付き）
    private func captureInitialTransforms() {
        // まず最大ジオメトリを基準にし、その上位から「操作対象コンテナ」を推定
        var container = findManipulableContainerNode(from: currentScene.rootNode)
            ?? findIPhoneBodyNode(from: currentScene.rootNode)
            ?? firstGeometryNode(in: currentScene.rootNode)

        // 名前の無いノードばかりでパスが作れない場合は、ルート直下に「manipulationRoot」を用意してそこにぶら下げる（初回のみ）
        if container == nil {
            container = currentScene.rootNode.childNode(withName: "manipulationRoot", recursively: false)
            if container == nil {
                let rootChilds = currentScene.rootNode.childNodes
                // ジオメトリ総量の多いノード群を新規ルートにまとめて移動（破壊的変更は避け、必要最低限の再親化）
                let newRoot = SCNNode()
                newRoot.name = "manipulationRoot"
                currentScene.rootNode.addChildNode(newRoot)
                for child in rootChilds {
                    // 既知のライト/カメラは除外
                    let lname = (child.name ?? "").lowercased()
                    if lname.contains("light") || lname.contains("camera") { continue }
                    child.removeFromParentNode()
                    newRoot.addChildNode(child)
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

        // カメラ
        let cameraNode = currentScene.rootNode.childNode(withName: "camera", recursively: true)
        initialCameraTransform = cameraNode?.transform
    }
    
    private func updateSceneWithImage(_ image: UIImage?, size: CGSize) {
        guard let image = image else {
            // 画像がクリアされた場合、元のシーンに戻す
            appState.clearImageState()
            withAnimation(.easeInOut(duration: 0.3)) {
                currentScene = originalScene
                updateSceneBackground(appState.settings, size: size)
            }
            // 初期Transformもリセット（元シーンの初期へ）
            captureInitialTransforms()
            // AppState保持値(0/1/0)を再反映
            applyAppStateTransform()
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
                    // 新しいシーンに対して初期Transformを取り直す
                    captureInitialTransforms()
                    // AppState保持値を反映（ユーザー操作状態を維持）
                    applyAppStateTransform()
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
    
    // MARK: - グリッドオーバーレイ
    struct GridOverlayView: View {
        // 画面密度やサイズに合わせて自動調整するが、基本は縦横に一定間隔でラインを描画
        var majorStep: Int = 4     // 太線の分割数（例: 4分割）
        var minorPerMajor: Int = 4 // 各メジャーの間を更に分割する数（細線）
    
        var body: some View {
            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height
    
                // 計算
                let majorColumns = CGFloat(majorStep)
                let majorRows = CGFloat(majorStep)
                let minorColumns = majorColumns * CGFloat(minorPerMajor)
                let minorRows = majorRows * CGFloat(minorPerMajor)
    
                ZStack {
                    // マイナーグリッド（薄い）
                    Path { path in
                        // 縦線
                        for i in 1..<Int(minorColumns) {
                            let x = width * CGFloat(i) / minorColumns
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: height))
                        }
                        // 横線
                        for j in 1..<Int(minorRows) {
                            let y = height * CGFloat(j) / minorRows
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                    }
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
    
                    // メジャーグリッド（やや強い）
                    Path { path in
                        // 縦線
                        for i in 1..<Int(majorColumns) {
                            let x = width * CGFloat(i) / majorColumns
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: height))
                        }
                        // 横線
                        for j in 1..<Int(majorRows) {
                            let y = height * CGFloat(j) / majorRows
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                    }
                    .stroke(Color.white.opacity(0.35), lineWidth: 1.0)
    
                    // 外枠を少し強調
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                }
                .blendMode(.screen) // 暗い背景の上で見やすくする
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
    
    // AppStateに保持している Transform を manipulationRoot へ適用
    private func applyAppStateTransform() {
        // 操作用ルートを取得（無ければ作成）
        let root = ensureManipulationRoot()
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0
        root.position = appState.objectPosition
        root.eulerAngles = appState.objectEulerAngles
        root.scale = appState.objectScale
        SCNTransaction.commit()
        SCNTransaction.flush()
    }

    // manipulationRoot を返す（無ければライト/カメラ以外をぶら下げて作成）
    @discardableResult
    private func ensureManipulationRoot() -> SCNNode {
        if let node = currentScene.rootNode.childNode(withName: "manipulationRoot", recursively: false) {
            return node
        }
        // 新規作成して、ライトとカメラ以外を再親化
        let newRoot = SCNNode()
        newRoot.name = "manipulationRoot"
        currentScene.rootNode.addChildNode(newRoot)

        // 現在の直下の子を走査して、ライト/カメラ以外を移動
        let children = currentScene.rootNode.childNodes
        for child in children {
            let lname = (child.name ?? "").lowercased()
            if lname == "manipulationroot" { continue }
            if lname.contains("light") || lname.contains("camera") { continue }
            child.removeFromParentNode()
            newRoot.addChildNode(child)
        }
        return newRoot
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
        lightNode.light!.intensity = 600
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        lightNode.eulerAngles = SCNVector3(x: -Float.pi/4, y: 0, z: 0)
        scene.rootNode.addChildNode(lightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.name = "ambientLight"
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor(white: 0.3, alpha: 1.0)
        ambientLightNode.light!.intensity = 240
        scene.rootNode.addChildNode(ambientLightNode)
        
        let fillLightNode = SCNNode()
        fillLightNode.name = "fillLight"
        fillLightNode.light = SCNLight()
        fillLightNode.light!.type = .omni
        fillLightNode.light!.color = UIColor(white: 0.6, alpha: 1.0)
        fillLightNode.light!.intensity = 100
        // 拡散感（光源を大きく感じるように減衰を緩やかに）
        fillLightNode.light!.attenuationStartDistance = 8.0
        fillLightNode.light!.attenuationEndDistance = 22.0
        fillLightNode.light!.attenuationFalloffExponent = 1.0
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
            
            // スナップショット取得前に最新のカメラトランスフォームを通知
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
