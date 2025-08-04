//
//  ManipulationTests.swift
//  AppMock3DTests
//
//  Created by Cascade on 2025/08/04.
//

import XCTest
@testable import AppMock3D
import SceneKit

class ManipulationTests: XCTestCase {
    var gestureManager: GestureManager!
    var transformManager: Transform3DManager!
    var testNode: SCNNode!
    
    override func setUp() {
        super.setUp()
        testNode = SCNNode()
        gestureManager = GestureManager(sceneView: nil, targetNode: testNode)
        transformManager = Transform3DManager(targetNode: testNode)
    }
    
    override func tearDown() {
        testNode = nil
        gestureManager = nil
        transformManager = nil
        super.tearDown()
    }
    
    // MARK: - InteractionMode Tests
    
    func testInteractionModeAllCases() {
        let allCases = InteractionMode.allCases
        XCTAssertEqual(allCases.count, 6)
        XCTAssertTrue(allCases.contains(.move))
        XCTAssertTrue(allCases.contains(.scale))
        XCTAssertTrue(allCases.contains(.rotate))
        XCTAssertTrue(allCases.contains(.aspect))
        XCTAssertTrue(allCases.contains(.background))
        XCTAssertTrue(allCases.contains(.device))
    }
    
    func testInteractionModeDisplayName() {
        XCTAssertEqual(InteractionMode.move.displayName, "移動")
        XCTAssertEqual(InteractionMode.scale.displayName, "拡大縮小")
        XCTAssertEqual(InteractionMode.rotate.displayName, "回転")
        XCTAssertEqual(InteractionMode.aspect.displayName, "アスペクト比")
        XCTAssertEqual(InteractionMode.background.displayName, "背景")
        XCTAssertEqual(InteractionMode.device.displayName, "デバイス")
    }
    
    func testInteractionModeIconName() {
        XCTAssertEqual(InteractionMode.move.iconName, "ic_move")
        XCTAssertEqual(InteractionMode.scale.iconName, "ic_scale")
        XCTAssertEqual(InteractionMode.rotate.iconName, "ic_rotate")
        XCTAssertEqual(InteractionMode.aspect.iconName, "ic_aspect")
        XCTAssertEqual(InteractionMode.background.iconName, "ic_background")
        XCTAssertEqual(InteractionMode.device.iconName, "ic_device")
    }
    
    // MARK: - Transform3DManager Tests
    
    func testSetPosition() {
        let newPosition = SCNVector3(1.0, 2.0, 3.0)
        transformManager.setPosition(newPosition)
        XCTAssertEqual(testNode.position, newPosition)
    }
    
    func testGetPosition() {
        let position = transformManager.getPosition()
        XCTAssertEqual(position, SCNVector3(0, 0, 0))
    }
    
    func testTranslate() {
        let translation = SCNVector3(1.0, -2.0, 3.0)
        transformManager.translate(translation)
        XCTAssertEqual(testNode.position, translation)
    }
    
    func testSetScale() {
        let newScale = SCNVector3(2.0, 2.0, 2.0)
        transformManager.setScale(newScale)
        XCTAssertEqual(testNode.scale, newScale)
    }
    
    func testGetScale() {
        let scale = transformManager.getScale()
        XCTAssertEqual(scale, SCNVector3(1, 1, 1))
    }
    
    func testScale() {
        let scaleVector = SCNVector3(2.0, 2.0, 2.0)
        transformManager.scale(scaleVector)
        XCTAssertEqual(testNode.scale, scaleVector)
    }
    
    func testSetRotation() {
        let newRotation = SCNVector3(Float.pi/2, Float.pi/4, Float.pi/6)
        transformManager.setRotation(newRotation)
        XCTAssertEqual(testNode.eulerAngles, newRotation)
    }
    
    func testGetRotation() {
        let rotation = transformManager.getRotation()
        XCTAssertEqual(rotation, SCNVector3(0, 0, 0))
    }
    
    func testRotate() {
        let rotationVector = SCNVector3(Float.pi/2, Float.pi/4, Float.pi/6)
        transformManager.rotate(rotationVector)
        XCTAssertEqual(testNode.eulerAngles, rotationVector)
    }
    
    func testResetTransform() {
        // 変換情報を変更
        testNode.position = SCNVector3(1.0, 2.0, 3.0)
        testNode.scale = SCNVector3(2.0, 2.0, 2.0)
        testNode.eulerAngles = SCNVector3(Float.pi/2, Float.pi/4, Float.pi/6)
        
        // リセット
        transformManager.resetTransform()
        
        // 確認
        XCTAssertEqual(testNode.position, SCNVector3(0, 0, 0))
        XCTAssertEqual(testNode.scale, SCNVector3(1, 1, 1))
        XCTAssertEqual(testNode.eulerAngles, SCNVector3(0, 0, 0))
    }
    
    // MARK: - GestureManager Tests
    
    func testSwitchMode() {
        gestureManager.switchMode(to: .scale)
        XCTAssertEqual(gestureManager.currentMode, .scale)
        
        gestureManager.switchMode(to: .rotate)
        XCTAssertEqual(gestureManager.currentMode, .rotate)
    }
    
    // MARK: - Performance Tests
    
    func testTransformPerformance() {
        measure {
            for _ in 0..<1000 {
                transformManager.translate(SCNVector3(0.1, 0.1, 0.1))
                transformManager.rotate(SCNVector3(0.1, 0.1, 0.1))
                transformManager.scale(SCNVector3(1.1, 1.1, 1.1))
            }
        }
    }
}
