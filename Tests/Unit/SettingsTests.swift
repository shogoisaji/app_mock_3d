import XCTest
import Combine
@testable import AppMock3D

class SettingsTests: XCTestCase {
    
    func testAppSettingsInitialization() {
        let settings = AppSettings()
        
        // Test default values
        XCTAssertEqual(settings.aspectRatioPreset, AppSettings.AspectRatioPreset.sixteenToNine)
        XCTAssertEqual(settings.customAspectRatio, 1.777)
        XCTAssertEqual(settings.width, 1080)
        XCTAssertEqual(settings.height, 1920)
        XCTAssertEqual(settings.maintainAspectRatio, true)
        XCTAssertEqual(settings.backgroundColor, AppSettings.BackgroundColorSetting.solidColor)
        XCTAssertEqual(settings.solidColorValue, "#FFFFFF")
        XCTAssertEqual(settings.gradientType, AppSettings.GradientType.linear)
        XCTAssertEqual(settings.environmentLightingIntensity, 1.0)
        XCTAssertEqual(settings.currentDeviceModel, AppSettings.DeviceModel.iPhone15)
    }
    
    func testAppSettingsAspectRatioPresets() {
        let presets = AppSettings.AspectRatioPreset.allCases
        
        // Test that all presets are available
        XCTAssertTrue(presets.contains(.sixteenToNine))
        XCTAssertTrue(presets.contains(.fourToThree))
        XCTAssertTrue(presets.contains(.oneToOne))
        XCTAssertTrue(presets.contains(.threeToFour))
        XCTAssertTrue(presets.contains(.nineToSixteen))
    }
    
    func testAppSettingsBackgroundColorOptions() {
        let backgroundOptions = AppSettings.BackgroundColorSetting.allCases
        
        // Test that all background options are available
        XCTAssertTrue(backgroundOptions.contains(.solidColor))
        XCTAssertTrue(backgroundOptions.contains(.transparent))
        XCTAssertTrue(backgroundOptions.contains(.gradient))
    }
    
    func testAppSettingsGradientTypes() {
        let gradientTypes = AppSettings.GradientType.allCases
        
        // Test that all gradient types are available
        XCTAssertTrue(gradientTypes.contains(.linear))
        XCTAssertTrue(gradientTypes.contains(.radial))
    }
    
    func testAppSettingsDeviceModels() {
        let deviceModels = AppSettings.DeviceModel.allCases
        
        // Test that all device models are available
        XCTAssertTrue(deviceModels.contains(.iPhone12))
        XCTAssertTrue(deviceModels.contains(.iPhone13))
        XCTAssertTrue(deviceModels.contains(.iPhone14))
        XCTAssertTrue(deviceModels.contains(.iPhone15))
    }
    
    func testAppSettingsSaveAndLoad() {
        var settings = AppSettings()
        
        // Modify settings
        settings.aspectRatioPreset = .oneToOne
        settings.customAspectRatio = 1.5
        settings.width = 800
        settings.height = 600
        settings.backgroundColor = .transparent
        settings.currentDeviceModel = .iPhone13
        
        // Save settings
        settings.save()
        
        // Load settings
        let loadedSettings = AppSettings.load()
        
        // Verify loaded settings match saved settings
        XCTAssertEqual(loadedSettings.aspectRatioPreset, .oneToOne)
        XCTAssertEqual(loadedSettings.customAspectRatio, 1.5)
        XCTAssertEqual(loadedSettings.width, 800)
        XCTAssertEqual(loadedSettings.height, 600)
        XCTAssertEqual(loadedSettings.backgroundColor, .transparent)
        XCTAssertEqual(loadedSettings.currentDeviceModel, .iPhone13)
    }
    
    func testColorConversion() {
        // Test hex to color conversion
        let white = Color(hex: "#FFFFFF")
        XCTAssertNotNil(white)
        
        let black = Color(hex: "#000000")
        XCTAssertNotNil(black)
        
        // Test color to hex conversion
        let whiteColor = Color.white
        let whiteHex = whiteColor.toHex()
        XCTAssertEqual(whiteHex, "#FFFFFF")
    }
    
    func testCustomAspectRatioValidation() {
        // Test valid custom aspect ratio values
        XCTAssertTrue(AppSettings.isValidCustomAspectRatio(0.1))
        XCTAssertTrue(AppSettings.isValidCustomAspectRatio(1.0))
        XCTAssertTrue(AppSettings.isValidCustomAspectRatio(5.0))
        XCTAssertTrue(AppSettings.isValidCustomAspectRatio(10.0))
        
        // Test invalid custom aspect ratio values
        XCTAssertFalse(AppSettings.isValidCustomAspectRatio(0.05))
        XCTAssertFalse(AppSettings.isValidCustomAspectRatio(15.0))
        XCTAssertFalse(AppSettings.isValidCustomAspectRatio(-1.0))
    }
    
    func testDimensionValidation() {
        // Test valid dimensions
        XCTAssertTrue(AppSettings.isValidWidth(100))
        XCTAssertTrue(AppSettings.isValidWidth(1080))
        XCTAssertTrue(AppSettings.isValidWidth(4096))
        
        XCTAssertTrue(AppSettings.isValidHeight(100))
        XCTAssertTrue(AppSettings.isValidHeight(1920))
        XCTAssertTrue(AppSettings.isValidHeight(4096))
        
        // Test invalid dimensions
        XCTAssertFalse(AppSettings.isValidWidth(50))
        XCTAssertFalse(AppSettings.isValidWidth(5000))
        XCTAssertFalse(AppSettings.isValidWidth(-100))
        
        XCTAssertFalse(AppSettings.isValidHeight(50))
        XCTAssertFalse(AppSettings.isValidHeight(5000))
        XCTAssertFalse(AppSettings.isValidHeight(-100))
    }
    
    func testLightingIntensityValidation() {
        // Test valid lighting intensity values
        XCTAssertTrue(AppSettings.isValidLightingIntensity(0.0))
        XCTAssertTrue(AppSettings.isValidLightingIntensity(1.0))
        XCTAssertTrue(AppSettings.isValidLightingIntensity(2.0))
        
        // Test invalid lighting intensity values
        XCTAssertFalse(AppSettings.isValidLightingIntensity(-0.5))
        XCTAssertFalse(AppSettings.isValidLightingIntensity(2.5))
    }
    
    func testSettingsUpdateNotification() {
        let settings = AppSettings()
        
        // Test that settings update notification is properly sent
        let expectation = XCTestExpectation(description: "Settings update notification received")
        
        let cancellable = NotificationCenter.default.publisher(for: .settingsDidUpdate)
            .sink { _ in
                expectation.fulfill()
            }
        
        settings.save()
        
        wait(for: [expectation], timeout: 1.0)
        
        // Clean up
        cancellable.cancel()
    }
}
