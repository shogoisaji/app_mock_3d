import XCTest
@testable import AppMock3D

class ImageHandlingTests: XCTestCase {
    var imagePickerManager: ImagePickerManager!
    var imageProcessingService: ImageProcessingService!
    var textureManager: TextureManager!
    
    override func setUp() {
        super.setUp()
        imagePickerManager = ImagePickerManager()
        imageProcessingService = ImageProcessingService()
        textureManager = TextureManager()
    }
    
    override func tearDown() {
        imagePickerManager = nil
        imageProcessingService = nil
        textureManager = nil
        super.tearDown()
    }
    
    func testImagePickerManagerInitialization() {
        XCTAssertNotNil(imagePickerManager)
        XCTAssertNil(imagePickerManager.selectedImage)
        XCTAssertFalse(imagePickerManager.isPresented)
    }
    
    func testImagePickerManagerSelectImage() {
        imagePickerManager.selectImage()
        XCTAssertTrue(imagePickerManager.isPresented)
    }
    
    func testImagePickerManagerClearImage() {
        // ダミーの画像を設定
        imagePickerManager.selectedImage = UIImage()
        XCTAssertNotNil(imagePickerManager.selectedImage)
        
        // 画像をクリア
        imagePickerManager.clearImage()
        XCTAssertNil(imagePickerManager.selectedImage)
    }
    
    func testImageProcessingServiceResizeImage() {
        // ダミーの大きな画像を作成
        let largeImage = createDummyImage(size: CGSize(width: 5000, height: 3000))
        let resizedImage = imageProcessingService.resizeImage(largeImage)
        
        XCTAssertNotNil(resizedImage)
        XCTAssertTrue(resizedImage!.size.width <= 4096)
    }
    
    func testImageProcessingServiceConvertToPNG() {
        let image = createDummyImage(size: CGSize(width: 100, height: 100))
        let pngData = imageProcessingService.convertToPNG(image)
        
        XCTAssertNotNil(pngData)
        XCTAssertTrue(pngData!.count > 0)
    }
    
    func testTextureManagerApplyTextureToModel() {
        let scene = SCNScene()
        let box = SCNBox(width: 0.1, height: 0.2, length: 0.05, chamferRadius: 0.01)
        let boxNode = SCNNode(geometry: box)
        scene.rootNode.addChildNode(boxNode)
        
        let image = createDummyImage(size: CGSize(width: 100, height: 100))
        let texturedScene = textureManager.applyTextureToModel(scene, image: image)
        
        XCTAssertNotNil(texturedScene)
        XCTAssertNotEqual(scene, texturedScene)
    }
    
    func testTextureManagerApplyTextureToModelWithData() {
        let scene = SCNScene()
        let box = SCNBox(width: 0.1, height: 0.2, length: 0.05, chamferRadius: 0.01)
        let boxNode = SCNNode(geometry: box)
        scene.rootNode.addChildNode(boxNode)
        
        let image = createDummyImage(size: CGSize(width: 100, height: 100))
        let imageData = image.pngData()!
        let texturedScene = textureManager.applyTextureToModel(scene, imageData: imageData)
        
        XCTAssertNotNil(texturedScene)
        XCTAssertNotEqual(scene, texturedScene)
    }
    
    // ダミー画像を作成するヘルパー関数
    func createDummyImage(size: CGSize) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor.red.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
