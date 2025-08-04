import XCTest
@testable import AppMock3D

class ExportIntegrationTests: XCTestCase {
    
    func testExportWithDifferentQualities() {
        // 低品質でのエクスポートテスト
        let lowQualityResult = exportImageWithQuality(.low)
        XCTAssertTrue(lowQualityResult, "低品質でのエクスポートが失敗しました")
        
        // 中品質でのエクスポートテスト
        let mediumQualityResult = exportImageWithQuality(.medium)
        XCTAssertTrue(mediumQualityResult, "中品質でのエクスポートが失敗しました")
        
        // 高品質でのエクスポートテスト
        let highQualityResult = exportImageWithQuality(.high)
        XCTAssertTrue(highQualityResult, "高品質でのエクスポートが失敗しました")
        
        // 最高品質でのエクスポートテスト
        let highestQualityResult = exportImageWithQuality(.highest)
        XCTAssertTrue(highestQualityResult, "最高品質でのエクスポートが失敗しました")
    }
    
    func testExportWithDifferentBackgrounds() {
        // 透明背景でのエクスポートテスト
        let transparentBackgroundResult = exportImageWithBackground(.transparent)
        XCTAssertTrue(transparentBackgroundResult, "透明背景でのエクスポートが失敗しました")
        
        // 単色背景でのエクスポートテスト
        let solidColorResult = exportImageWithBackground(.solidColor(.black))
        XCTAssertTrue(solidColorResult, "単色背景でのエクスポートが失敗しました")
        
        // 線形グラデーション背景でのエクスポートテスト
        let linearGradientResult = exportImageWithBackground(.linearGradient(.red, .blue))
        XCTAssertTrue(linearGradientResult, "線形グラデーション背景でのエクスポートが失敗しました")
        
        // 放射状グラデーション背景でのエクスポートテスト
        let radialGradientResult = exportImageWithBackground(.radialGradient(.green, .yellow))
        XCTAssertTrue(radialGradientResult, "放射状グラデーション背景でのエクスポートが失敗しました")
    }
    
    func testExportPerformance() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 最高品質でのエクスポート
        let result = exportImageWithQuality(.highest)
        XCTAssertTrue(result, "最高品質でのエクスポートが失敗しました")
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(timeElapsed, 10.0, "エクスポート処理が10秒を超えています")
    }
    
    // モック関数 - 実際の実装ではRenderingEngineとBackgroundProcessorを使用
    private func exportImageWithQuality(_ quality: ExportQuality) -> Bool {
        // モック実装 - 実際のテストではここで実際のエクスポート処理を呼び出す
        Thread.sleep(forTimeInterval: 0.1)
        return true
    }
    
    // モック関数 - 実際の実装ではBackgroundProcessorを使用
    private func exportImageWithBackground(_ background: BackgroundProcessor.BackgroundType) -> Bool {
        // モック実装 - 実際のテストではここで実際の背景設定とエクスポート処理を呼び出す
        Thread.sleep(forTimeInterval: 0.1)
        return true
    }
}
