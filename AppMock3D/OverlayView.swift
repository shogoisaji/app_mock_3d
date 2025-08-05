
//
//  OverlayView.swift
//  AppMock3D
//
//  Created by shogo isaji on 2025/08/06.
//

import SwiftUI

struct OverlayView: View {
    @ObservedObject var appState: AppState
    @Binding var isSaving: Bool

    var body: some View {
        ZStack {
            // ローディング状態の表示
            if appState.isImageProcessing {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#E99370") ?? .orange))
                    Text("画像を処理中...")
                        .foregroundColor(Color(hex: "#E99370") ?? .orange)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.5))
            }

            // エラー状態の表示
            if let error = appState.imageError {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(Color(hex: "#E99370") ?? .orange)
                    Text("エラー")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#E99370") ?? .orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "#E99370") ?? .orange)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("再試行") {
                        appState.clearImageState()
                    }
                    .foregroundColor(.black)
                    .padding()
                    .background(Color(hex: "#E99370") ?? .orange)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.7))
            }

            // 保存中の表示
            if isSaving {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#E99370") ?? .orange))
                    Text("画像を保存中...")
                        .foregroundColor(Color(hex: "#E99370") ?? .orange)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.5))
            }
        }
    }
}
