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
    // 追加: エクスポート用に最新シーンを保持
    @State private var latestSceneForExport: SCNScene?
    @State private var showingImagePicker = false
    @State private var showingPermissionAlert = false
    @State private var isSaving = false
    @State private var showSaveSuccessAlert = false
    @State private var showSaveErrorAlert = false
    @State private var showingExportView = false
    // 追加: プレビューのカメラ行列を保持
    @State private var latestCameraTransform: SCNMatrix4?
    // 追加: プレビューのスナップショット画像を保持
    @State private var currentPreviewSnapshot: UIImage?
    // 追加: スナップショット要求のトリガー
    @State private var shouldTakeSnapshot = false
    
    var body: some View {
        MainView(
            appState: appState,
            imagePickerManager: imagePickerManager,
            sceneView: $sceneView,
            latestSceneForExport: $latestSceneForExport,
            latestCameraTransform: $latestCameraTransform,
            currentPreviewSnapshot: $currentPreviewSnapshot,
            shouldTakeSnapshot: $shouldTakeSnapshot,
            showingExportView: $showingExportView,
            isSaving: $isSaving,
            handleImageButtonPressed: handleImageButtonPressed
        )
        .tint(Color(hex: "#E99370") ?? .orange) // アクセントカラー
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
        .sheet(isPresented: $appState.isSettingsPresented) {
            NavigationView {
                SettingsView(appState: appState)
                    .navigationTitle("設定")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("完了") {
                                appState.isSettingsPresented = false
                            }
                        }
                    }
            }
        }
        .alert("保存完了", isPresented: $showSaveSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("画像をフォトライブラリに保存しました。")
        }
        .alert("保存エラー", isPresented: $showSaveErrorAlert) {
            Button("OK") { }
        } message: {
            Text("画像の保存に失敗しました。")
        }
        .alert("写真へのアクセス許可", isPresented: $showingPermissionAlert) {
            Button("設定を開く") {
                openAppSettings()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("画像を選択するには、写真ライブラリへのアクセスを許可してください。設定アプリで「AppMock3D」のアクセス権限を変更できます。")
        }
        .sheet(isPresented: $showingExportView) {
            // スナップショット画像がある場合はそれを使用
            if let snapshot = currentPreviewSnapshot {
                ExportView(renderingEngine: nil,
                           photoSaveManager: PhotoSaveManager(),
                           cameraTransform: $latestCameraTransform,
                           aspectRatio: appState.aspectRatio,
                           previewSnapshot: snapshot)
            } else if let exportScene = latestSceneForExport ?? sceneView {
                // フォールバック: RenderingEngineを使用
                let renderingEngine = RenderingEngine(scene: exportScene)
                ExportView(renderingEngine: renderingEngine,
                           photoSaveManager: PhotoSaveManager(),
                           cameraTransform: $latestCameraTransform,
                           aspectRatio: appState.aspectRatio,
                           previewSnapshot: nil)
            } else {
                Text("エクスポートするシーンがありません。")
            }
        }
    }
    
    private func loadModel() {
        // Load the default iPhone model
        let model = ModelManager.shared.loadModel(named: "iphone14pro")
        
        if model == nil {
            appState.setImageError("3Dモデルの読み込みに失敗しました。アプリを再起動してください。")
        } else {
            sceneView = model
            // 初期ロード時点のシーンをエクスポート用にセット
            latestSceneForExport = model
        }
    }
    
    private func handleImageButtonPressed() {
        // 権限をチェック
        photoPermissionManager.checkAuthorizationStatus()
        
        switch photoPermissionManager.authorizationStatus {
        case .authorized:
            // 権限がある場合は直接PhotosPickerを表示
            showingImagePicker = true
        case .notDetermined:
            // 初回の場合は権限を要求
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
            // 拒否されている場合はアラートを表示
            showingPermissionAlert = true
        case .limited:
            // 制限付きアクセスでも画像選択は可能
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







