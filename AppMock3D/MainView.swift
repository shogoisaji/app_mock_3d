
//
//  MainView.swift
//  AppMock3D
//
//  Created by shogo isaji on 2025/08/06.
//

import SwiftUI
import SceneKit

struct MainView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var imagePickerManager: ImagePickerManager
    
    @Binding var sceneView: SCNScene?
    @Binding var latestSceneForExport: SCNScene?
    @Binding var latestCameraTransform: SCNMatrix4?
    @Binding var currentPreviewSnapshot: UIImage?
    @Binding var shouldTakeSnapshot: Bool
    @Binding var showingExportView: Bool
    @Binding var isSaving: Bool
    
    var handleImageButtonPressed: () -> Void
    
    // 設定に基づいた背景色を取得
    private var backgroundColor: Color {
        switch appState.settings.backgroundColor {
        case .solidColor:
            return Color(hex: appState.settings.solidColorValue) ?? Color(hex: "#303135") ?? Color(red: 48/255, green: 49/255, blue: 53/255)
        case .gradient:
            // グラデーションの場合は開始色を使用
            return Color(hex: appState.settings.gradientStartColor) ?? Color(hex: "#303135") ?? Color(red: 48/255, green: 49/255, blue: 53/255)
        case .transparent:
            // 透明の場合はデフォルトのダークグレーを使用
            return Color(hex: "#303135") ?? Color(red: 48/255, green: 49/255, blue: 53/255)
        }
    }
    
    var body: some View {
        ZStack {
            Color(.clear)
                .background(backgroundColor)
                .ignoresSafeArea()
            Color(.clear)
                .background(Color(.black.opacity(0.1)))
                .ignoresSafeArea()

            Group {
                if let scene = sceneView {
                    ZStack {
                        ThreeDSceneView(
                            appState: appState,
                            imagePickerManager: imagePickerManager,
                            scene: $sceneView,
                            latestSceneForExport: $latestSceneForExport,
                            latestCameraTransform: $latestCameraTransform,
                            currentPreviewSnapshot: $currentPreviewSnapshot,
                            shouldTakeSnapshot: $shouldTakeSnapshot,
                            showingExportView: $showingExportView
                        )
                        OverlayView(appState: appState, isSaving: $isSaving)
                    }
                } else {
                    Text("3Dモデルを読み込んでいます...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityIdentifier("Loading 3D Model")
                }
            }
            .ignoresSafeArea(edges: .all)

            VStack(spacing: 0) {
                AppBarView(title: "", onSave: {
                    shouldTakeSnapshot = true
                }, onSettings: {
                    appState.toggleSettings()
                }, onImageSelect: {
                    handleImageButtonPressed()
                })
                .accessibilityIdentifier("AppBar")
                .padding(.top, 0)
                
                Spacer()
                
                HStack {
                    BottomAppBarView(
                        onGridToggle: {
                            appState.toggleGrid()
                        },
                        onLightingAdjust: {
                            appState.cycleLightingPosition()
                        },
                        onResetTransform: {
                            appState.triggerResetTransform()
                        },
                        lightingNumber: appState.lightingPositionNumber
                    )
                    .accessibilityIdentifier("BottomAppBar")
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 0)
        }
    }
}
