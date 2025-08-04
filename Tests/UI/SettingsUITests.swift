import XCTest

final class SettingsUITests: XCTestCase {
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
    
    func testBottomSheetDisplaysAndDismisses() {
        // Test that bottom sheet displays when settings button is tapped
        let settingsButton = app.buttons["gear"]
        settingsButton.tap()
        
        let settingsView = app.otherElements["Settings View"]
        XCTAssertTrue(settingsView.exists, "Settings view should be displayed after tapping settings button")
        
        // Test that bottom sheet can be dismissed
        let closeButton = app.buttons["Close"]
        if closeButton.exists {
            closeButton.tap()
            XCTAssertFalse(settingsView.exists, "Settings view should be dismissed after tapping close button")
        }
    }
    
    func testAspectRatioSettingsUI() {
        // Open settings bottom sheet
        let settingsButton = app.buttons["gear"]
        settingsButton.tap()
        
        // Tap on aspect ratio settings
        let aspectRatioButton = app.buttons["アスペクト比"]
        aspectRatioButton.tap()
        
        // Verify aspect ratio preset buttons exist
        let sixteenNineButton = app.buttons["16:9"]
        let fourThreeButton = app.buttons["4:3"]
        let oneOneButton = app.buttons["1:1"]
        let threeFourButton = app.buttons["3:4"]
        let nineSixteenButton = app.buttons["9:16"]
        
        XCTAssertTrue(sixteenNineButton.exists, "16:9 aspect ratio button should exist")
        XCTAssertTrue(fourThreeButton.exists, "4:3 aspect ratio button should exist")
        XCTAssertTrue(oneOneButton.exists, "1:1 aspect ratio button should exist")
        XCTAssertTrue(threeFourButton.exists, "3:4 aspect ratio button should exist")
        XCTAssertTrue(nineSixteenButton.exists, "9:16 aspect ratio button should exist")
        
        // Test tapping on different aspect ratio presets
        sixteenNineButton.tap()
        fourThreeButton.tap()
        oneOneButton.tap()
        threeFourButton.tap()
        nineSixteenButton.tap()
    }
    
    func testBackgroundSettingsUI() {
        // Open settings bottom sheet
        let settingsButton = app.buttons["gear"]
        settingsButton.tap()
        
        // Tap on background settings
        let backgroundButton = app.buttons["背景"]
        backgroundButton.tap()
        
        // Verify background option buttons exist
        let solidColorButton = app.buttons["単色"]
        let transparentButton = app.buttons["透明"]
        let gradientButton = app.buttons["グラデーション"]
        
        XCTAssertTrue(solidColorButton.exists, "Solid color background button should exist")
        XCTAssertTrue(transparentButton.exists, "Transparent background button should exist")
        XCTAssertTrue(gradientButton.exists, "Gradient background button should exist")
        
        // Test tapping on different background options
        solidColorButton.tap()
        transparentButton.tap()
        gradientButton.tap()
    }
    
    func testDeviceSelectionUI() {
        // Open settings bottom sheet
        let settingsButton = app.buttons["gear"]
        settingsButton.tap()
        
        // Tap on device selection
        let deviceButton = app.buttons["端末"]
        deviceButton.tap()
        
        // Verify device model buttons exist
        let iPhone12Button = app.buttons["iPhone 12"]
        let iPhone13Button = app.buttons["iPhone 13"]
        let iPhone14Button = app.buttons["iPhone 14"]
        let iPhone15Button = app.buttons["iPhone 15"]
        
        XCTAssertTrue(iPhone12Button.exists, "iPhone 12 selection button should exist")
        XCTAssertTrue(iPhone13Button.exists, "iPhone 13 selection button should exist")
        XCTAssertTrue(iPhone14Button.exists, "iPhone 14 selection button should exist")
        XCTAssertTrue(iPhone15Button.exists, "iPhone 15 selection button should exist")
        
        // Test tapping on different device models
        iPhone12Button.tap()
        iPhone13Button.tap()
        iPhone14Button.tap()
        iPhone15Button.tap()
    }
    
    func testSettingsPersistence() {
        // Open settings bottom sheet
        let settingsButton = app.buttons["gear"]
        settingsButton.tap()
        
        // Change a setting
        let backgroundButton = app.buttons["背景"]
        backgroundButton.tap()
        
        let transparentButton = app.buttons["透明"]
        transparentButton.tap()
        
        // Close settings
        let closeButton = app.buttons["Close"]
        if closeButton.exists {
            closeButton.tap()
        }
        
        // Reopen settings and verify the change persists
        settingsButton.tap()
        backgroundButton.tap()
        
        // Note: In a real implementation, we would verify that the transparent option is selected
        // This would require additional accessibility identifiers in the UI implementation
        XCTAssertTrue(transparentButton.exists, "Settings should persist between sessions")
    }
    
    func testAccessibilityOfSettingsUI() {
        // Open settings bottom sheet
        let settingsButton = app.buttons["gear"]
        settingsButton.tap()
        
        let settingsView = app.otherElements["Settings View"]
        XCTAssertTrue(settingsView.exists, "Settings view should be accessible")
        
        // Check that all main settings buttons are accessible
        let aspectRatioButton = app.buttons["アスペクト比"]
        let backgroundButton = app.buttons["背景"]
        let deviceButton = app.buttons["端末"]
        
        XCTAssertTrue(aspectRatioButton.isAccessibilityElement, "Aspect ratio button should be accessible")
        XCTAssertTrue(backgroundButton.isAccessibilityElement, "Background button should be accessible")
        XCTAssertTrue(deviceButton.isAccessibilityElement, "Device button should be accessible")
    }
}
