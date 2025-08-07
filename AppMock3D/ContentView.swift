//
//  ContentView.swift
//  AppMock3D
//
//  Created by shogo isaji on 2025/08/04.
//

import SwiftUI
import SceneKit
import UIKit
import Foundation

struct ContentView: View {
    @StateObject private var appState = AppState()
    @StateObject private var imagePickerManager = ImagePickerManager()
    @StateObject private var photoPermissionManager = PhotoPermissionManager()
    @StateObject private var photoSaveManager = PhotoSaveManager()
    @State private var sceneView: SCNScene?
    // Added: Hold the latest scene for export
    @State private var latestSceneForExport: SCNScene?
    @State private var showingImagePicker = false
    @State private var showingPermissionAlert = false
    @State private var isSaving = false
    @State private var showSaveSuccessAlert = false
    @State private var showSaveErrorAlert = false
    @State private var showingExportView = false
    // Added: Hold the camera matrix of the preview
    @State private var latestCameraTransform: SCNMatrix4?
    // Added: Hold the snapshot image of the preview
    @State private var currentPreviewSnapshot: UIImage?
    // Added: Trigger for snapshot request
    @State private var shouldTakeSnapshot = false
    
    var body: some View {
        ZStack {
            MainView(
                appState: appState,
                imagePickerManager: imagePickerManager,
                sceneView: $sceneView,
                latestSceneForExport: $latestSceneForExport,
                latestCameraTransform: $latestCameraTransform,
                currentPreviewSnapshot: $currentPreviewSnapshot,
                shouldTakeSnapshot: $shouldTakeSnapshot,
                isSaving: $isSaving,
                handleImageButtonPressed: handleImageButtonPressed
            )
            .tint(Color(hex: "#E99370") ?? .orange) // Accent color
            .onAppear {
                loadModel()
            }
            .photosPicker(
                isPresented: $showingImagePicker,
                selection: $imagePickerManager.selectedItem,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: imagePickerManager.selectedItem) { _, _ in
                imagePickerManager.loadImage()
            }
            
            BottomSheetManager(
                isOpen: $appState.isSettingsPresented,
                content: SettingsView(appState: appState)
            )
            .animation(.easeInOut(duration: appState.isSettingsPresented ? 0.4 : 0.3), value: appState.isSettingsPresented)
            
            BottomSheetManager(
                isOpen: $appState.isMenuPresented,
                content: MenuView(appState: appState)
            )
            .animation(.easeInOut(duration: appState.isMenuPresented ? 0.4 : 0.3), value: appState.isMenuPresented)
        }
        .alert("Save Complete", isPresented: $showSaveSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("The image has been saved to your photo library.")
        }
        .alert("Save Error", isPresented: $showSaveErrorAlert) {
            Button("OK") { }
        } message: {
            Text("Failed to save the image.")
        }
        .alert("Photo Library Access", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) { } 
        } message: {
            Text("To select an image, please allow access to your photo library. You can change permissions in the Settings app for \"AppMock3D\".")
        }
        .onChange(of: currentPreviewSnapshot) { _, newSnapshot in
            if newSnapshot != nil {
                showingExportView = true
            }
        }
        .sheet(isPresented: $showingExportView) {
            // Use the snapshot image if it exists
            if let snapshot = currentPreviewSnapshot {
                ExportView(renderingEngine: nil,
                           photoSaveManager: PhotoSaveManager(),
                           cameraTransform: $latestCameraTransform,
                           aspectRatio: appState.aspectRatio,
                           previewSnapshot: snapshot)
            } else if let exportScene = latestSceneForExport ?? sceneView {
                // Fallback: Use RenderingEngine
                let renderingEngine = RenderingEngine(scene: exportScene)
                ExportView(renderingEngine: renderingEngine,
                           photoSaveManager: PhotoSaveManager(),
                           cameraTransform: $latestCameraTransform,
                           aspectRatio: appState.aspectRatio,
                           previewSnapshot: nil)
            } else {
                // Last resort: Create a new scene and export
                let fallbackScene = ModelManager.shared.loadModel(named: "iphone1") ?? SCNScene()
                let renderingEngine = RenderingEngine(scene: fallbackScene)
                ExportView(renderingEngine: renderingEngine,
                           photoSaveManager: PhotoSaveManager(),
                           cameraTransform: $latestCameraTransform,
                           aspectRatio: appState.aspectRatio,
                           previewSnapshot: nil)
            }
        }
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                // Open the settings app
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To select an image, please allow access to your photo library. You can change permissions in the Settings app for \"AppMock3D\".")
        }
    }
    
    private func loadModel() {
        // Load the default iPhone model
        let model = ModelManager.shared.loadModel(.iphone15)
        
        if model == nil {
            appState.setImageError("Failed to load 3D model. Please restart the app.")
        } else {
            sceneView = model
            // Set the scene at initial load for export
            latestSceneForExport = model
        }
    }
    
    private func handleImageButtonPressed() {
        // Check for permissions
        photoPermissionManager.checkAuthorizationStatus()
        
        switch photoPermissionManager.authorizationStatus {
        case .authorized:
            // If authorized, show PhotosPicker directly
            showingImagePicker = true
        case .notDetermined:
            // If first time, request permission
            Task {
                let status = await photoPermissionManager.requestPermission()
                DispatchQueue.main.async {
                    if status == .authorized {
                        self.showingImagePicker = true
                    } else {
                        self.showingPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            // If denied, show an alert
            showingPermissionAlert = true
        case .limited:
            // Image selection is possible even with limited access
            showingImagePicker = true
        @unknown default:
            showingPermissionAlert = true
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}







