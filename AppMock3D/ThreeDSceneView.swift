
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
    
    var onHighResExportReady: (@escaping (ExportQuality, @escaping (UIImage?) -> Void) -> Void) -> Void
    
    // Store reference to high-res export function
    @State private var previewHighResExport: ((ExportQuality, @escaping (UIImage?) -> Void) -> Void)?
    // Store reference to preview view
    @State private var previewAreaViewRef: PreviewAreaView?

    var body: some View {
        if let scene = scene {
            PreviewAreaView(
                currentScene: Binding(get: { scene }, set: { newValue in self.scene = newValue }), 
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
            .onAppear {
                // Set up high-resolution export callback that uses the actual preview
                let highResCallback: (ExportQuality, @escaping (UIImage?) -> Void) -> Void = { quality, completion in
                    #if DEBUG
                    print("[ThreeDSceneView] High-res export requested for quality: \(quality)")
                    #endif
                    
                    // Use a global reference to find the SCNView
                    DispatchQueue.main.async {
                        // Search for SCNView in the current window
                        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                              let window = windowScene.windows.first else {
                            #if DEBUG
                            print("[ThreeDSceneView] Could not find window")
                            #endif
                            completion(nil)
                            return
                        }
                        
                        // Find SCNView in the view hierarchy
                        if let scnView = findSCNView(in: window) {
                            #if DEBUG
                            print("[ThreeDSceneView] Found SCNView, taking high-res snapshot")
                            #endif
                            takeHighResSnapshot(from: scnView, quality: quality, completion: completion)
                        } else {
                            #if DEBUG
                            print("[ThreeDSceneView] Could not find SCNView")
                            #endif
                            completion(nil)
                        }
                    }
                }
                
                previewHighResExport = highResCallback
                onHighResExportReady(highResCallback)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("3D Preview")
            // keep identity stable to allow background color changes to propagate
        } else {
            Text("Loading 3D Model...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("Loading 3D Model")
        }
    }
    
    // Helper function to find SCNView in the view hierarchy
    private func findSCNView(in view: UIView) -> SCNView? {
        if let scnView = view as? SCNView {
            return scnView
        }
        
        for subview in view.subviews {
            if let found = findSCNView(in: subview) {
                return found
            }
        }
        
        return nil
    }
    
    // Helper function to take high-resolution snapshot without mutating the live SCNView
    private func takeHighResSnapshot(from scnView: SCNView, quality: ExportQuality, completion: @escaping (UIImage?) -> Void) {
        // Calculate high resolution size based on quality and current aspect
        let baseResolution = quality.resolution
        let currentAspectRatio = max(0.0001, scnView.frame.width / max(1, scnView.frame.height))

        var targetSize: CGSize
        if currentAspectRatio > 1.0 {
            targetSize = CGSize(width: baseResolution.width, height: baseResolution.width / currentAspectRatio)
        } else {
            targetSize = CGSize(width: baseResolution.height * currentAspectRatio, height: baseResolution.height)
        }

        // Cap to avoid memory pressure
        let maxDimension: CGFloat = 4096
        let maxSide = max(targetSize.width, targetSize.height)
        if maxSide > maxDimension {
            let scale = maxDimension / maxSide
            targetSize = CGSize(width: floor(targetSize.width * scale), height: floor(targetSize.height * scale))
        }

        #if DEBUG
        print("[ThreeDSceneView] Taking high-res snapshot at size: \(targetSize)")
        print("[ThreeDSceneView] Current SCNView size: \(scnView.frame.size)")
        print("[ThreeDSceneView] Camera position: \(scnView.pointOfView?.position ?? SCNVector3Zero)")
        #endif

        // Use SCNRenderer to render offscreen at arbitrary size without touching the live view
        let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
        renderer.scene = scnView.scene
        renderer.pointOfView = scnView.pointOfView
        renderer.autoenablesDefaultLighting = scnView.autoenablesDefaultLighting
        renderer.showsStatistics = false

        // Render on a background queue to avoid blocking UI; deliver on main
        DispatchQueue.global(qos: .userInitiated).async {
            let image = renderer.snapshot(atTime: 0, with: targetSize, antialiasingMode: .multisampling4X)
            DispatchQueue.main.async {
                #if DEBUG
                print("[ThreeDSceneView] High-res snapshot completed. Size: \(image.size)")
                #endif
                completion(image)
            }
        }
    }
}
