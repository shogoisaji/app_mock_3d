import SwiftUI

struct DeviceSelectionView: View {
    @Binding var settings: AppSettings
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("端末モデル選択")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)
            
            // Device model selection
            VStack(alignment: .leading, spacing: 10) {
                Text("端末モデル")
                    .font(.headline)
                
                Picker("端末モデル", selection: $settings.currentDeviceModel) {
                    ForEach(AppSettings.DeviceModel.allCases, id: \.rawValue) { model in
                        Text(model.rawValue).tag(model)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 150)
            }
            
            // Device preview information
            VStack(alignment: .leading, spacing: 10) {
                Text("モデル情報")
                    .font(.headline)
                
                HStack {
                    Text("選択中のモデル:")
                    Spacer()
                    Text(settings.currentDeviceModel.rawValue)
                        .fontWeight(.bold)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            Spacer()
            
            // Action buttons
            HStack {
                Button("キャンセル") {
                    isPresented = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray5))
                .cornerRadius(8)
                
                Button("適用") {
                    settings.save()
                    isPresented = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

struct DeviceSelectionView_Previews: PreviewProvider {
    @State static var settings = AppSettings()
    @State static var isPresented = true
    
    static var previews: some View {
        DeviceSelectionView(settings: $settings, isPresented: $isPresented)
    }
}
