import SwiftUI

struct ExportView: View {
    @State private var selectedQuality: ExportQuality = .high
    @State private var isExporting: Bool = false
    @State private var exportProgress: Double = 0.0
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var renderingEngine: RenderingEngine
    var photoSaveManager: PhotoSaveManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("エクスポート設定")
                .font(.title)
                .padding()
            
            Picker("品質設定", selection: $selectedQuality) {
                ForEach(ExportQuality.allCases, id: \.self) {
                    quality in
                    Text(quality.displayName).tag(quality)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Button(action: {
                exportImage()
            }) {
                Text("画像をエクスポート")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(isExporting)
            
            if isExporting {
                ProgressView("エクスポート中...", value: exportProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
            }
            
            Spacer()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("エクスポート結果"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func exportImage() {
        isExporting = true
        exportProgress = 0.0
        
        renderingEngine.renderImage(withQuality: selectedQuality) { image in
            guard let image = image else {
                self.isExporting = false
                self.alertMessage = "画像のエクスポートに失敗しました。"
                self.showAlert = true
                return
            }
            
            photoSaveManager.saveImageToPhotoLibrary(image) { success, error in
                self.isExporting = false
                if success {
                    self.alertMessage = "画像が写真ライブラリに保存されました。"
                } else {
                    self.alertMessage = "画像の保存に失敗しました: \(error?.localizedDescription ?? "不明なエラー")"
                }
                self.showAlert = true
            }
        }
    }
}
