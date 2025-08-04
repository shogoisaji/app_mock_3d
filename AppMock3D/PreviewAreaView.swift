import SwiftUI
import SceneKit

struct PreviewAreaView: View {
    var scene: SCNScene
    @ObservedObject var appState: AppState
    @ObservedObject var imagePickerManager: ImagePickerManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Darken the area outside the viewport
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                
                // Preview area with border
                PreviewView(scene: scene)
                    .frame(width: geometry.size.width, height: geometry.size.width * appState.aspectRatio)
                    .border(Color.white, width: 2)
                    .clipped()
                
                // Image picker button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ImagePickerView(imagePickerManager: imagePickerManager, permissionManager: PhotoPermissionManager())
                            .padding()
                    }
                }
            }
        }
    }
}

struct PreviewAreaView_Previews: PreviewProvider {
    static var previews: some View {
        let scene = SCNScene()
        let box = SCNBox(width: 0.1, height: 0.2, length: 0.05, chamferRadius: 0.01)
        let boxNode = SCNNode(geometry: box)
        scene.rootNode.addChildNode(boxNode)
        
        return PreviewAreaView(scene: scene, appState: AppState(), imagePickerManager: ImagePickerManager())
    }
}
