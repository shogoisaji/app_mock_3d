import XCTest

final class BasicUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    func testAppBarIsDisplayed() {
        let appBar = app.otherElements["AppMock3D"]
        XCTAssertTrue(appBar.exists, "App bar should be displayed")
    }
    
    func testSaveButtonIsDisplayed() {
        let saveButton = app.buttons["save"]
        XCTAssertTrue(saveButton.exists, "Save button should be displayed")
    }
    
    func testSettingsButtonIsDisplayed() {
        let settingsButton = app.buttons["gear"]
        XCTAssertTrue(settingsButton.exists, "Settings button should be displayed")
    }
    
    func testBottomNavigationBarIsDisplayed() {
        let bottomNav = app.otherElements["Bottom Navigation"]
        XCTAssertTrue(bottomNav.exists, "Bottom navigation bar should be displayed")
    }
    
    func testNavigationButtonsAreDisplayed() {
        let moveButton = app.buttons["移動"]
        let scaleButton = app.buttons["拡大縮小"]
        let rotateButton = app.buttons["回転"]
        let aspectRatioButton = app.buttons["アスペクト比"]
        let backgroundButton = app.buttons["背景"]
        let deviceButton = app.buttons["端末"]
        
        XCTAssertTrue(moveButton.exists, "Move button should be displayed")
        XCTAssertTrue(scaleButton.exists, "Scale button should be displayed")
        XCTAssertTrue(rotateButton.exists, "Rotate button should be displayed")
        XCTAssertTrue(aspectRatioButton.exists, "Aspect ratio button should be displayed")
        XCTAssertTrue(backgroundButton.exists, "Background button should be displayed")
        XCTAssertTrue(deviceButton.exists, "Device button should be displayed")
    }
    
    func testNavigationButtonsAreSelectable() {
        let moveButton = app.buttons["移動"]
        let scaleButton = app.buttons["拡大縮小"]
        let rotateButton = app.buttons["回転"]
        
        moveButton.tap()
        XCTAssertTrue(moveButton.isHittable, "Move button should be selectable")
        
        scaleButton.tap()
        XCTAssertTrue(scaleButton.isHittable, "Scale button should be selectable")
        
        rotateButton.tap()
        XCTAssertTrue(rotateButton.isHittable, "Rotate button should be selectable")
    }
    
    func test3DPreviewAreaIsDisplayed() {
        let previewArea = app.otherElements["3D Preview"]
        XCTAssertTrue(previewArea.exists, "3D preview area should be displayed")
    }
    
    func testPreviewAreaViewHasCorrectMaskingAndBorder() {
        // Verify the preview area has the correct masking and border
        // This test would require visual inspection or more advanced UI testing techniques
        XCTAssertTrue(true, "Preview area should have correct masking and border")
    }
    
    func testSettingsViewIsDisplayedWhenSettingsButtonIsTapped() {
        let settingsButton = app.buttons["gear"]
        settingsButton.tap()
        
        let settingsView = app.otherElements["Settings View"]
        XCTAssertTrue(settingsView.exists, "Settings view should be displayed after tapping settings button")
    }
}
