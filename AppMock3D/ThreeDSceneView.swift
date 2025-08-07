
//
//  ThreeDSceneView.swift
//  AppMock3D
//
//  Created by shogo isaji on 2025/08/06.
//

import SwiftUI
import SceneKit

struct ThreeDSceneView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var imagePickerManager: ImagePickerManager
    
    @Binding var scene: SCNScene?
    @Binding var latestSceneForExport: SCNScene?
    @Binding var latestCameraTransform: SCNMatrix4?
    @Binding var currentPreviewSnapshot: UIImage?
    @Binding var shouldTakeSnapshot: Bool

    var body: some View {
        if let scene = scene {
            PreviewAreaView(
                scene: scene, 
                appState: appState, 
                imagePickerManager: imagePickerManager, 
                shouldTakeSnapshot: $shouldTakeSnapshot, 
                onSceneUpdated: { updated in
                    latestSceneForExport = updated
                }, 
                onCameraUpdated: { transform in
                    latestCameraTransform = transform
                }, 
                onSnapshotRequested: { snapshot in
                    currentPreviewSnapshot = snapshot
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("3D Preview")
        } else {
            Text("Loading 3D Model...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("Loading 3D Model")
        }
    }
}
