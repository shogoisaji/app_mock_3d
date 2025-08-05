import XCTest
import SwiftUI
import SceneKit
@testable import AppMock3D

final class ImageTextureIntegrationTests: XCTestCase {
    var textureManager: TextureManager!
    var testScene: SCNScene!
    var testImage: UIImage!
    
    override func setUpWithError() throws {
        textureManager = TextureManager.shared
        
        // テスト用の3Dシーンを作成
        testScene = SCNScene()
        let screenNode = SCNNode()
        screenNode.name = "screen"
        screenNode.geometry = SCNBox(width: 1, height: 1, length: 0.1, chamferRadius: 0)
        testScene.rootNode.addChildNode(screenNode)
        
        // テスト用の画像を作成
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        testImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    override func tearDownWithError() throws {
        textureManager.clearCache()
        testScene = nil
        testImage = nil
    }
    
    func testImageToTextureIntegration() throws {
        // Given: テスト用のシーンと画像
        XCTAssertNotNil(testScene)
        XCTAssertNotNil(testImage)
        
        // When: テクスチャを適用
        let result = textureManager.applyTextureToModel(testScene, image: testImage)
        
        // Then: 正しくテクスチャが適用されたシーンが返される
        XCTAssertNotNil(result)
        
        // 画面ノードが存在することを確認
        var screenFound = false
        result?.rootNode.enumerateChildNodes { node, _ in
            if node.name == "screen" {
                screenFound = true
                XCTAssertNotNil(node.geometry)
                
                // マテリアルにテクスチャが適用されていることを確認
                if let geometry = node.geometry {
                    XCTAssertGreaterThan(geometry.materials.count, 0)
                    let material = geometry.materials[0]
                    XCTAssertNotNil(material.diffuse.contents)
                }
            }
        }
        XCTAssertTrue(screenFound, "Screen node should be found and textured")
    }
    
    func testDifferentImageSizes() throws {
        let sizes = [
            CGSize(width: 50, height: 50),
            CGSize(width: 1000, height: 1000),
            CGSize(width: 2048, height: 2048),
            CGSize(width: 4000, height: 4000) // これは最適化される
        ]
        
        for size in sizes {
            // 各サイズの画像を作成
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            UIColor.blue.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            guard let testImageForSize = image else {
                XCTFail("Failed to create test image for size \(size)")
                continue
            }
            
            // テクスチャを適用
            let result = textureManager.applyTextureToModel(testScene, image: testImageForSize)
            XCTAssertNotNil(result, "Should handle image of size \(size)")
        }
    }
    
    func testTextureManagerCaching() throws {
        // Given: 同じ画像を複数回適用
        let firstResult = textureManager.applyTextureToModel(testScene, image: testImage)
        let secondResult = textureManager.applyTextureToModel(testScene, image: testImage)
        
        // Then: 両方とも結果が返される（キャッシュが機能している）
        XCTAssertNotNil(firstResult)
        XCTAssertNotNil(secondResult)
        
        // キャッシュ情報を確認
        let cacheInfo = textureManager.getCacheInfo()
        XCTAssertGreaterThan(cacheInfo.textureCount, 0)
        XCTAssertGreaterThan(cacheInfo.sceneCount, 0)
    }
    
    func testMemoryManagement() throws {
        // Given: メモリ使用量をテスト
        let initialCacheInfo = textureManager.getCacheInfo()
        
        // When: 複数の異なる画像でテクスチャを適用
        for i in 0..<5 {
            let size = CGSize(width: 100, height: 100)
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            UIColor(hue: CGFloat(i) / 5.0, saturation: 1.0, brightness: 1.0, alpha: 1.0).setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            if let testImageForLoop = image {
                _ = textureManager.applyTextureToModel(testScene, image: testImageForLoop)
            }
        }
        
        // When: キャッシュをクリア
        textureManager.clearCache()
        
        // Then: キャッシュがクリアされている
        let finalCacheInfo = textureManager.getCacheInfo()
        // キャッシュがクリアされた後も基本的な設定は保持される
        XCTAssertEqual(finalCacheInfo.textureCount, initialCacheInfo.textureCount)
        XCTAssertEqual(finalCacheInfo.sceneCount, initialCacheInfo.sceneCount)
    }
    
    func testPerformanceOfTextureApplication() throws {
        // Given: パフォーマンステスト用の大きな画像
        let size = CGSize(width: 1024, height: 1024)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.green.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let largeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let testLargeImage = largeImage else {
            XCTFail("Failed to create large test image")
            return
        }
        
        // When & Then: パフォーマンステスト
        measure {
            let result = textureManager.applyTextureToModel(testScene, image: testLargeImage)
            XCTAssertNotNil(result)
        }
    }
    
    func testErrorHandling() throws {
        // Given: 画面ノードが存在しないシーン
        let emptyScene = SCNScene()
        
        // When: テクスチャを適用
        let result = textureManager.applyTextureToModel(emptyScene, image: testImage)
        
        // Then: nilが返される（エラーハンドリング）
        XCTAssertNil(result, "Should return nil when screen node is not found")
    }
    
    func testAppStateIntegration() throws {
        // Given: AppStateのテスト
        let appState = AppState()
        
        // When: 各状態を設定
        appState.setImageProcessing(true)
        XCTAssertTrue(appState.isImageProcessing)
        XCTAssertNil(appState.imageError)
        
        appState.setImageError("Test error")
        XCTAssertFalse(appState.isImageProcessing)
        XCTAssertEqual(appState.imageError, "Test error")
        
        appState.setImageApplied(true)
        XCTAssertTrue(appState.hasImageApplied)
        XCTAssertNil(appState.imageError)
        
        appState.clearImageState()
        XCTAssertFalse(appState.hasImageApplied)
        XCTAssertFalse(appState.isImageProcessing)
        XCTAssertNil(appState.imageError)
    }
}