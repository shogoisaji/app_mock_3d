
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
            // Display loading state
            if appState.isImageProcessing {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#E99370") ?? .orange))
                    Text(NSLocalizedString("processing_image", comment: "Processing Image..."))
                        .foregroundColor(Color(hex: "#E99370") ?? .orange)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.5))
            }

            // Display error state
            if let error = appState.imageError {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(Color(hex: "#E99370") ?? .orange)
                    Text(NSLocalizedString("error", comment: "Error"))
                        .font(.headline)
                        .foregroundColor(Color(hex: "#E99370") ?? .orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "#E99370") ?? .orange)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button(NSLocalizedString("retry", comment: "Retry")) {
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

            // Display saving state
            if isSaving {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#E99370") ?? .orange))
                    Text(NSLocalizedString("saving_image", comment: "Saving Image..."))
                        .foregroundColor(Color(hex: "#E99370") ?? .orange)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.5))
            }
        }
    }
}
