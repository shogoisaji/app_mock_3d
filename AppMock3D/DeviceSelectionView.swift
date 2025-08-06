import SwiftUI

struct DeviceSelectionView: View {
    @Binding var settings: AppSettings
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Select Device Model")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)
            
            // Device model selection
            VStack(alignment: .leading, spacing: 10) {
                Text("Device Model")
                    .font(.headline)
                
                Picker("Device Model", selection: $settings.currentDeviceModel) {
                    ForEach(AppSettings.DeviceModel.allCases, id: \.rawValue) { model in
                        Text(model.rawValue).tag(model)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 150)
            }
            
            // Device preview information
            VStack(alignment: .leading, spacing: 10) {
                Text("Model Information")
                    .font(.headline)
                
                HStack {
                    Text("Selected Model:")
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
                Button("Cancel") {
                    isPresented = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray5))
                .cornerRadius(8)
                
                Button("Apply") {
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
