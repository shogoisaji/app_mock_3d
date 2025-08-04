import XCTest
@testable import AppMock3D

class ExportTests: XCTestCase {
    
    func testExportQualityResolution() {
        XCTAssertEqual(ExportQuality.low.resolution, CGSize(width: 512, height: 512))
        XCTAssertEqual(ExportQuality.medium.resolution, CGSize(width: 1024, height: 1024))
        XCTAssertEqual(ExportQuality.high.resolution, CGSize(width: 2048, height: 2048))
        XCTAssertEqual(ExportQuality.highest.resolution, CGSize(width: 4096, height: 4096))
    }
    
    func testExportQualityAntiAliasing() {
        XCTAssertEqual(ExportQuality.low.antiAliasing, 1)
        XCTAssertEqual(ExportQuality.medium.antiAliasing, 2)
        XCTAssertEqual(ExportQuality.high.antiAliasing, 4)
        XCTAssertEqual(ExportQuality.highest.antiAliasing, 8)
    }
    
    func testExportQualitySamplingQuality() {
        XCTAssertEqual(ExportQuality.low.samplingQuality, 1)
        XCTAssertEqual(ExportQuality.medium.samplingQuality, 2)
        XCTAssertEqual(ExportQuality.high.samplingQuality, 4)
        XCTAssertEqual(ExportQuality.highest.samplingQuality, 8)
    }
    
    func testExportQualityDisplayName() {
        XCTAssertEqual(ExportQuality.low.displayName, "低品質")
        XCTAssertEqual(ExportQuality.medium.displayName, "中品質")
        XCTAssertEqual(ExportQuality.high.displayName, "高品質")
        XCTAssertEqual(ExportQuality.highest.displayName, "最高品質")
    }
}
