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
    @State private var showingSaveDialog = false
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
                handleImageButtonPressed: handleImageButtonPressed,
                onHighResExportReady: { callback in
                    self.highResExportCallback = callback
                }
            )
            .tint(Color(hex: "#E99370") ?? .orange) // Accent color
            .onAppear {
                loadModel()
            }
            // 端末変更時にモデルを再ロードし、アニメーション付きで再表示
            .onChange(of: appState.settings.currentDeviceModel) { _, _ in
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82, blendDuration: 0.1)) {
                    reloadModelForCurrentSelection()
                }
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
            
            // 個別設定シート: アスペクト比
            BottomSheetManager(
                isOpen: $appState.isAspectSheetPresented,
                content: AspectRatioSettingsView(settings: $appState.settings, isPresented: $appState.isAspectSheetPresented),
                maxWidth: 400
            )
            .animation(.easeInOut(duration: appState.isAspectSheetPresented ? 0.4 : 0.3), value: appState.isAspectSheetPresented)

            // 個別設定シート: デバイス
            BottomSheetManager(
                isOpen: $appState.isDeviceSheetPresented,
                content: DeviceSelectionView(settings: $appState.settings, isPresented: $appState.isDeviceSheetPresented),
                maxWidth: 400
            )
            .animation(.easeInOut(duration: appState.isDeviceSheetPresented ? 0.4 : 0.3), value: appState.isDeviceSheetPresented)

            BottomSheetManager(
                isOpen: $appState.isMenuPresented,
                content: MenuView(appState: appState),
                maxWidth: 400
            )
            .animation(.easeInOut(duration: appState.isMenuPresented ? 0.4 : 0.3), value: appState.isMenuPresented)
        }
        .alert(NSLocalizedString("save_complete_title", comment: ""), isPresented: $showSaveSuccessAlert) {
            Button(NSLocalizedString("ok", comment: "")) { }
        } message: {
            Text(NSLocalizedString("save_complete_message", comment: ""))
        }
        .alert(NSLocalizedString("save_error_title", comment: ""), isPresented: $showSaveErrorAlert) {
            Button(NSLocalizedString("ok", comment: "")) { }
        } message: {
            Text(NSLocalizedString("save_error_message", comment: ""))
        }
        .alert(NSLocalizedString("photo_access_title", comment: ""), isPresented: $showingPermissionAlert) {
            Button(NSLocalizedString("open_settings", comment: "")) {
                openAppSettings()
            }
            Button(NSLocalizedString("cancel", comment: ""), role: .cancel) { } 
        } message: {
            Text(NSLocalizedString("photo_access_message", comment: ""))
        }
        .onChange(of: currentPreviewSnapshot) { _, newSnapshot in
            if newSnapshot != nil {
                showingSaveDialog = true
            }
        }
        .onChange(of: showingSaveDialog) { _, shouldShow in
            if shouldShow {
                showSystemSaveDialog()
            }
        }
        .alert(NSLocalizedString("permission_required_title", comment: ""), isPresented: $showingPermissionAlert) {
            Button(NSLocalizedString("open_settings", comment: "")) {
                // Open the settings app
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button(NSLocalizedString("cancel", comment: ""), role: .cancel) { }
        } message: {
            Text(NSLocalizedString("photo_access_message", comment: ""))
        }
    }
    
    private func loadModel() {
        // Load the model based on current settings
        let model = ModelManager.shared.loadModel(appState.currentDevice)
        
        if model == nil {
            appState.setImageError("Failed to load 3D model. Please restart the app.")
        } else {
            sceneView = model
            // Set the scene at initial load for export
            latestSceneForExport = model
        }
    }

    private func reloadModelForCurrentSelection() {
        let asset = appState.selectedModelAsset
        #if DEBUG
        print("[DeviceSwitch] selected DeviceModel=\(appState.settings.currentDeviceModel.rawValue), asset=\(asset.rawValue)")
        #endif
        let model = ModelManager.shared.loadModel(asset)
        if let scene = model {
            sceneView = scene
            latestSceneForExport = scene
            // 端末切替完了トークンを更新して、プレビュー側に確実に通知
            appState.deviceReloadToken += 1
            // 新しいデバイス表示に向けて transform を既定状態へ（アニメの終点と一致させる）
            appState.resetObjectTransformState()
            
            // 選択された画像がある場合、新しいシーンに再適用
            if let selectedImage = imagePickerManager.selectedImage {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // TextureManagerを使って新しいシーンに画像を適用（Data引数に合わせて変換）
                    let imageData: Data? = selectedImage.pngData() ?? selectedImage.jpegData(compressionQuality: 0.95)
                    if let data = imageData, let updatedScene = TextureManager.shared.applyTextureToModel(scene, imageData: data) {
                        self.sceneView = updatedScene
                        self.latestSceneForExport = updatedScene
                        self.appState.setImageApplied(true)
                        #if DEBUG
                        print("[DeviceSwitch] Reapplied selected image to new device model")
                        #endif
                    }
                }
            }
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
    
    
    
    private func showSystemSaveDialog() {
        showingSaveDialog = false // Reset the state
        
        let alert = UIAlertController(title: nil, message: NSLocalizedString("save_confirm_message", comment: "Do you want to save?"), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("save", comment: "Save"), style: .default) { _ in
            self.exportImageDirectly()
        })
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: "Cancel"), style: .cancel) { _ in
            // Do nothing, just dismiss
        })
        
        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }

    private func exportImageDirectly() {
        isSaving = true
        
        #if DEBUG
        print("[Export] Using ACTUAL preview SCNView for 100% consistency")
        #endif
        
        // Use the high-resolution export callback from the preview
        if let callback = highResExportCallback {
            callback(.ultra) { image in
                DispatchQueue.main.async {
                    guard let image = image else {
                        self.isSaving = false
                        self.showSaveErrorAlert = true
                        return
                    }
                    self.saveImageToPhotoLibrary(image)
                }
            }
        } else {
            #if DEBUG
            print("[Export] High-res export callback not available")
            #endif
            isSaving = false
            showSaveErrorAlert = true
        }
    }
    
    // Store reference to high-resolution export callback
    @State private var highResExportCallback: ((ExportQuality, @escaping (UIImage?) -> Void) -> Void)?
    
    private func saveImageToPhotoLibrary(_ image: UIImage) {
        // 常にPNGで保存して高画質・アルファ保持
        let preferPNG = true
        photoSaveManager.saveImageToPhotoLibrary(image, preferPNG: preferPNG) { success, error in
            DispatchQueue.main.async {
                self.isSaving = false
                if success {
                    self.showSaveSuccessAlert = true
                } else {
                    self.showSaveErrorAlert = true
                }
            }
        }
    }

    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}









