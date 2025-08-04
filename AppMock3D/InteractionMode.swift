//
//  InteractionMode.swift
//  AppMock3D
//
//  Created by Cascade on 2025/08/04.
//

import Foundation

/// 3D操作の各モードを定義するenum
enum InteractionMode: String, CaseIterable {
    /// 移動モード
    case move = "move"
    
    /// 拡大縮小モード
    case scale = "scale"
    
    /// 回転モード
    case rotate = "rotate"
    
    /// アスペクト比変更モード
    case aspect = "aspect"
    
    /// 背景設定モード
    case background = "background"
    
    /// デバイス選択モード
    case device = "device"
    
    /// 各モードの表示名を返す
    var displayName: String {
        switch self {
        case .move:
            return "移動"
        case .scale:
            return "拡大縮小"
        case .rotate:
            return "回転"
        case .aspect:
            return "アスペクト比"
        case .background:
            return "背景"
        case .device:
            return "デバイス"
        }
    }
    
    /// 各モードのアイコン名を返す
    var iconName: String {
        switch self {
        case .move:
            return "ic_move"
        case .scale:
            return "ic_scale"
        case .rotate:
            return "ic_rotate"
        case .aspect:
            return "ic_aspect"
        case .background:
            return "ic_background"
        case .device:
            return "ic_device"
        }
    }
}
