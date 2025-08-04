import SwiftUI

struct ExportView: View {
    @State private var selectedQuality: ExportQuality = .high
    @State private var isExporting: Bool = false
    @State private var exportProgress: Double = 0.0
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("エクスポート設定")
                .font(.title)
                .padding()
            
            Picker("品質設定", selection: $selectedQuality) {
                ForEach(ExportQuality.allCases, id: \.self) { quality in
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
                
                Button(action: {
                    cancelExport()
                }) {
                    Text("キャンセル")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            
            Spacer()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("エクスポート完了"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func exportImage() {
        isExporting = true
        exportProgress = 0.0
        
        // ここで実際のエクスポート処理を呼び出す
        // 現在はモック実装
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 1...10 {
                if !self.isExporting { return }
                DispatchQueue.main.async {
                    self.exportProgress = Double(i) / 10.0
                }
                Thread.sleep(forTimeInterval: 0.5)
            }
            
            DispatchQueue.main.async {
                self.isExporting = false
                self.alertMessage = "画像が写真ライブラリに保存されました"
                self.showAlert = true
            }
        }
    }
    
    private func cancelExport() {
        isExporting = false
        alertMessage = "エクスポートがキャンセルされました"
        showAlert = true
    }
}
