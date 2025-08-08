import SwiftUI
import SceneKit

class AppState: ObservableObject {
    
    @Published var isSettingsPresented: Bool = false
    @Published var isMenuPresented: Bool = false
    @Published var settings: AppSettings = AppSettings.load()

    // 追加: 個別設定用ボトムシートの表示状態
    @Published var isBackgroundSheetPresented: Bool = false
    @Published var isAspectSheetPresented: Bool = false
    @Published var isDeviceSheetPresented: Bool = false
    
    // 設定値
    @Published var backgroundColor: Color = .white
    // 中央集約したモデル管理（ModelAsset）に変更
    @Published var currentDevice: ModelAsset = .iphone16
    // 端末モデルの切替に伴い、ビューを確実に再構築させるためのトークン
    @Published var deviceReloadToken: Int = 0
    // 設定の DeviceModel から使用する実ファイル（ModelAsset）を決めるためのヘルパ
    var selectedModelAsset: ModelAsset {
        switch settings.currentDeviceModel {
        case .iPhone16:
            return .iphone16
        case .iPhoneSE:
            return .iphoneSE
        default:
            return .iphone16
        }
    }
    
    // アスペクト比を設定から計算
    var aspectRatio: Double {
        switch settings.aspectRatioPreset {
        case .sixteenToNine:
            return 16.0 / 9.0
        case .fourToThree:
            return 4.01 / 3.0
        case .oneToOne:
            return 1.0
        case .threeToFour:
            return 3.0 / 4.0
        case .nineToSixteen:
            return 9.0 / 16.0
        }
    }
    
    // 画像関連の状態管理
    @Published var isImageProcessing: Bool = false
    @Published var imageError: String?
    @Published var hasImageApplied: Bool = false

    // 追加: ボトムバーの機能状態
    @Published var isGridVisible: Bool = false

    enum LightingPreset: String, CaseIterable {
        case neutral
        case warm
        case cool
    }
    @Published var lightingPreset: LightingPreset = .neutral

    // 新規: ライティングポジション（1〜10）
    enum LightingPosition: Int, CaseIterable {
        case one = 1, two, three, four, five, six, seven, eight, nine, ten
    }
    @Published var lightingPosition: LightingPosition = .one
    var lightingPositionNumber: Int { lightingPosition.rawValue }

    // リセットトリガー（トグルで変化させて監視側で反応）
    @Published var resetTransformToggle: Bool = false

    // デフォルトスケール（少し小さめに表示）
    static let defaultScale: SCNVector3 = SCNVector3(0.9, 0.9, 0.9)

    // 3Dオブジェクトの操作状態（manipulationRoot に適用）
    @Published var objectPosition: SCNVector3 = SCNVector3(0, 0, 0)
    @Published var objectEulerAngles: SCNVector3 = SCNVector3(0, 0, 0)
    @Published var objectScale: SCNVector3 = AppState.defaultScale

    // 値の更新ヘルパ
    func setObjectPosition(_ p: SCNVector3) { 
        objectPosition = p 
    }
    func setObjectEuler(_ r: SCNVector3) { 
        objectEulerAngles = r 
    }
    func setObjectScale(_ s: SCNVector3) { 
        objectScale = s 
    }

    // リセット（位置/回転は0、スケールは既定値へ）
    func resetObjectTransformState() {
        objectPosition = SCNVector3(0, 0, 0)
        objectEulerAngles = SCNVector3(0, 0, 0)
        objectScale = AppState.defaultScale
    }
    
    func toggleSettings() {
        isSettingsPresented.toggle()
    }
    
    func toggleMenu() {
        isMenuPresented.toggle()
    }

    // 個別シートトグル
    func toggleBackgroundSheet() { isBackgroundSheetPresented.toggle() }
    func toggleAspectSheet() { isAspectSheetPresented.toggle() }
    func toggleDeviceSheet() { isDeviceSheetPresented.toggle() }

    // グリッド切替
    func toggleGrid() {
        isGridVisible.toggle()
    }

    // ライティングプリセットを順送り（既存）
    func cycleLightingPreset() {
        let all = LightingPreset.allCases
        if let idx = all.firstIndex(of: lightingPreset) {
            let next = all.index(after: idx)
            lightingPreset = next < all.endIndex ? all[next] : all.first!
        } else {
            lightingPreset = .neutral
        }
    }
    
    // 新規: ライティングポジションを1→4で循環
    func cycleLightingPosition() {
        let all = LightingPosition.allCases
        if let idx = all.firstIndex(of: lightingPosition) {
            let nextIdx = all.index(after: idx)
            lightingPosition = nextIdx < all.endIndex ? all[nextIdx] : all.first!
        } else {
            lightingPosition = .one
        }
    }

    // リセット発火
    func triggerResetTransform() {
        resetTransformToggle.toggle()
    }
    
    func setImageProcessing(_ processing: Bool) {
        isImageProcessing = processing
        if processing {
            imageError = nil
        }
    }
    
    func setImageError(_ error: String?) {
        imageError = error
        isImageProcessing = false
    }
    
    func setImageApplied(_ applied: Bool) {
        hasImageApplied = applied
        if applied {
            imageError = nil
        }
    }
    
    func clearImageState() {
        hasImageApplied = false
        imageError = nil
        isImageProcessing = false
    }
}
