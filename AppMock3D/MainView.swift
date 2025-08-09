
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
    @Binding var isSaving: Bool
    
    var handleImageButtonPressed: () -> Void
    // Get the background color based on settings
    private var backgroundColor: Color {
        switch appState.settings.backgroundColor {
        case .solidColor:
            return Color(hex: appState.settings.solidColorValue) ?? Color(hex: "#303135") ?? Color(red: 48/255, green: 49/255, blue: 53/255)
        case .gradient:
            // Use the start color for gradients
            return Color(hex: appState.settings.gradientStartColor) ?? Color(hex: "#303135") ?? Color(red: 48/255, green: 49/255, blue: 53/255)
        case .transparent:
            // Use the default dark gray for transparent
            return Color(hex: "#303135") ?? Color(red: 48/255, green: 49/255, blue: 53/255)
        }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#D1D1D1")
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
                            shouldTakeSnapshot: $shouldTakeSnapshot
                        )
                        // デバイス変更時の再表示アニメーション
                        .id(appState.settings.currentDeviceModel.rawValue)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.96).combined(with: .opacity),
                            removal: .opacity
                        ))
                        OverlayView(appState: appState, isSaving: $isSaving)
                    }
                } else {
                    Text("Loading 3D Model...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityIdentifier("Loading 3D Model")
                }
            }
            .ignoresSafeArea(edges: .all)

            VStack(spacing: 0) {
                AppBarView(title: "", onSave: {
                    shouldTakeSnapshot = true
                }, onImageSelect: {
                    handleImageButtonPressed()
                }, onMenu: {
                    appState.toggleMenu()
                })
                .accessibilityIdentifier("AppBar")
                .padding(.top, 0)
                
                Spacer()
                Spacer()

                // Bottom area stack: app bar only (background color is picked directly on the button)
                VStack(spacing: 8) {
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
                            backgroundColorBinding: Binding(get: {
                                backgroundColor
                            }, set: { newColor in
                                // ColorPicker で色を選んだら背景モードを Solid に切替え、
                                // 構造体を再代入して @Published を発火させ、永続化も行う
                                var s = appState.settings
                                s.backgroundColor = .solidColor
                                s.solidColorValue = newColor.toHex()
                                appState.settings = s
                                appState.settings.save()
                            }),
                            onTransparentTap: {
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                var s = appState.settings
                                s.backgroundColor = .transparent
                                appState.settings = s
                                appState.settings.save()
                            },
                            onAspectTap: {
                                appState.toggleAspectSheet()
                            },
                            onDeviceTap: {
                                appState.toggleDeviceSheet()
                            },
                            lightingNumber: appState.lightingPositionNumber,
                            backgroundDisplayColor: backgroundColor,
                            aspectRatio: appState.aspectRatio,
                            deviceLabel: appState.settings.currentDeviceModel.label
                        )
                        .accessibilityIdentifier("BottomAppBar")
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }
            .padding(.horizontal, 0)
        }
    }
}
