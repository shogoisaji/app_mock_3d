import SceneKit
import UIKit
import AVFoundation

class RenderingEngine {
    private var scene: SCNScene
    private var renderer: SCNRenderer

    init(scene: SCNScene) {
        self.scene = scene
        self.renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
        self.scene = scene
    }

    func renderImage(
        withQuality quality: ExportQuality,
        aspectRatio: Double = 1.0,
        backgroundColor: UIColor? = nil,
        cameraTransform: SCNMatrix4? = nil,
        completion: @escaping (UIImage?) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let baseResolution = quality.resolution
            let antiAliasing = quality.antiAliasing

            let renderSize = self.calculateRenderSize(aspectRatio: aspectRatio, baseResolution: baseResolution)

            let cameraNode = self.getOrCreateCameraNode()
            self.configureCamera(cameraNode)

            if let transform = cameraTransform {
                cameraNode.transform = transform
            }

            self.renderer.pointOfView = cameraNode
            self.renderer.isTemporalAntialiasingEnabled = antiAliasing > 1

            if let bgColor = backgroundColor {
                self.scene.background.contents = bgColor
            }

            let image = self.renderer.snapshot(
                atTime: 0,
                with: renderSize,
                antialiasingMode: antiAliasing > 1 ? .multisampling4X : .none
            )

            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    private func getOrCreateCameraNode() -> SCNNode {
        if let existing = self.scene.rootNode.childNode(withName: "camera", recursively: true) {
            return existing
        } else {
            let node = SCNNode()
            node.name = "camera"
            node.camera = SCNCamera()
            node.position = SCNVector3(x: 0, y: 0, z: 5)
            node.look(at: SCNVector3(x: 0, y: 0, z: 0))
            self.scene.rootNode.addChildNode(node)
            return node
        }
    }

    private func configureCamera(_ node: SCNNode) {
        guard let camera = node.camera else { return }
        camera.fieldOfView = 60
        camera.automaticallyAdjustsZRange = true
        camera.zNear = 0.1
        camera.zFar = 100
    }

    private func calculateRenderSize(aspectRatio: Double, baseResolution: CGSize) -> CGSize {
        if aspectRatio > 1.0 {
            return CGSize(width: baseResolution.width,
                          height: baseResolution.width / aspectRatio)
        } else {
            return CGSize(width: baseResolution.height * aspectRatio,
                          height: baseResolution.height)
        }
    }

    func renderVideo(
        withQuality quality: ExportQuality,
        aspectRatio: Double = 1.0,
        backgroundColor: UIColor? = nil,
        cameraTransform: SCNMatrix4? = nil,
        duration: TimeInterval = 5.0,
        framesPerSecond: Int = 30,
        completion: @escaping (URL?) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let baseResolution = quality.resolution
            let antiAliasing = quality.antiAliasing
            let renderSize = self.calculateRenderSize(aspectRatio: aspectRatio, baseResolution: baseResolution)

            let cameraNode = self.getOrCreateCameraNode()
            self.configureCamera(cameraNode)
            if let transform = cameraTransform {
                cameraNode.transform = transform
            }

            self.renderer.pointOfView = cameraNode
            self.renderer.isTemporalAntialiasingEnabled = antiAliasing > 1
            if let bgColor = backgroundColor {
                self.scene.background.contents = bgColor
            }

            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")

            guard let assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: renderSize.width,
                AVVideoHeightKey: renderSize.height
            ]
            let assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            let pixelBufferAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput, sourcePixelBufferAttributes: nil)

            guard assetWriter.canAdd(assetWriterInput) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            assetWriter.add(assetWriterInput)

            guard assetWriter.startWriting() else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            assetWriter.startSession(atSourceTime: .zero)

            let modelNode = self.scene.rootNode.childNode(withName: "modelNode", recursively: true) ?? self.scene.rootNode.childNodes.first { $0.camera == nil }
            let originalTransform = modelNode?.transform ?? SCNMatrix4Identity

            let totalFrames = Int(duration * Double(framesPerSecond))
            let frameQueue = DispatchQueue(label: "video-frame-queue")

            assetWriterInput.requestMediaDataWhenReady(on: frameQueue) {
                for frame in 0..<totalFrames {
                    guard assetWriterInput.isReadyForMoreMediaData else { continue }

                    let presentationTime = CMTime(value: Int64(frame), timescale: Int32(framesPerSecond))

                    let angle = (2 * .pi) * (Float(frame) / Float(totalFrames))
                    let rotation = SCNMatrix4MakeRotation(angle, 0, 1, 0)

                    if let node = modelNode {
                        node.transform = SCNMatrix4Mult(rotation, originalTransform)
                    }

                    let image = self.renderer.snapshot(atTime: 0, with: renderSize, antialiasingMode: antiAliasing > 1 ? .multisampling4X : .none)

                    if let buffer = self.pixelBuffer(from: image, size: renderSize) {
                        pixelBufferAdapter.append(buffer, withPresentationTime: presentationTime)
                    }
                }

                assetWriterInput.markAsFinished()
                assetWriter.finishWriting {
                    if let node = modelNode {
                        node.transform = originalTransform
                    }
                    DispatchQueue.main.async {
                        completion(assetWriter.status == .completed ? outputURL : nil)
                    }
                }
            }
        }
    }

    private func pixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let options: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, options as CFDictionary, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(buffer)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }

        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        UIGraphicsPopContext()

        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))

        return buffer
    }
}