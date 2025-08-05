import SceneKit
import Foundation

/// Utility for locating and loading 3D model files from the app bundle.
/// This class centralises the logic for searching supported file extensions
/// and loading a `SCNScene` from a URL.
final class ModelFileLocator {
    /// Supported 3D file extensions in order of preference.
    private static let supportedExtensions = ["usdc", "usdz", "dae", "scn", "obj"]

    /// Attempts to locate a model file with the given name in the bundle
    /// (first in the main bundle, then in the `Assets` directory).
    /// - Parameter modelName: The base name of the model (without extension).
    /// - Returns: A URL to the model file if found, otherwise `nil`.
    static func locateModel(named modelName: String) -> URL? {
        for ext in supportedExtensions {
            // Search in the main bundle.
            if let url = Bundle.main.url(forResource: modelName, withExtension: ext) {
                print("Found \(ext.uppercased()) file in bundle: \(modelName).\(ext)")
                return url
            }

            // Search in the Assets directory.
            if let url = Bundle.main.url(forResource: "Assets/\(modelName)", withExtension: ext) {
                print("Found \(ext.uppercased()) file in Assets: \(modelName).\(ext)")
                return url
            }
        }

        print("No supported 3D model found for: \(modelName)")
        return nil
    }

    /// Loads a `SCNScene` from the given URL using a set of
    /// `SCNSceneSource.LoadingOption` values that preserve
    /// the original model data as much as possible.
    /// - Parameter url: The URL of the model file.
    /// - Returns: A loaded `SCNScene` or `nil` on failure.
    static func loadScene(from url: URL) -> SCNScene? {
        do {
            print("Loading 3D model from: \(url.path)")

            let sceneSource = SCNSceneSource(url: url, options: nil)

            // Debug: list identifiers of geometries and nodes.
            if let identifiers = sceneSource?.identifiersOfEntries(withClass: SCNGeometry.self) {
                print("Geometry identifiers: \(identifiers)")
            }
            if let nodeIdentifiers = sceneSource?.identifiersOfEntries(withClass: SCNNode.self) {
                print("Node identifiers: \(nodeIdentifiers)")
            }

            let scene = try SCNScene(url: url, options: [
                SCNSceneSource.LoadingOption.convertToYUp: true,
                SCNSceneSource.LoadingOption.convertUnitsToMeters: false,
                SCNSceneSource.LoadingOption.preserveOriginalTopology: true,
                SCNSceneSource.LoadingOption.strictConformance: false,
                SCNSceneSource.LoadingOption.createNormalsIfAbsent: true,
                SCNSceneSource.LoadingOption.checkConsistency: false
            ])

            print("Successfully loaded 3D model from \(url.pathExtension.uppercased())")
            return scene
        } catch {
            print("Failed to load 3D model from \(url.path): \(error)")
            return nil
        }
    }
}