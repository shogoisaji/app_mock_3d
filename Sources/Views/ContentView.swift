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
    @State private var sceneView: SCNScene?
    
    var body: some View {
        VStack(spacing: 0) {
            // App Bar
            AppBarView(title: "", onSave: {
                // Save functionality
            }, onSettings: {
                appState.toggleSettings()
            })
            .accessibilityIdentifier("AppBar")
            
            // 3D Preview Area
            if let scene = sceneView {
                PreviewAreaView(scene: scene, appState: appState, imagePickerManager: imagePickerManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityIdentifier("3D Preview")
            } else {
                Text("3Dモデルを読み込んでいます...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityIdentifier("Loading 3D Model")
            }
            
            // Settings View is presented as a sheet controlled by appState.isSettingsPresented
            BottomNavView(appState: appState)
                .accessibilityIdentifier("Bottom Navigation")
        }
        .sheet(isPresented: $appState.isSettingsPresented) {
            SettingsView(appState: appState)
                .accessibilityIdentifier("Settings View")
        }
        .onAppear {
            // Load the default iPhone model
            sceneView = ModelManager.shared.loadModel(named: "iphone15")
        }
    }
}

struct PreviewView: UIViewRepresentable {
    var scene: SCNScene
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        scnView.backgroundColor = UIColor.black
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update view if needed
    }
}

#Preview {
    ContentView()
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
