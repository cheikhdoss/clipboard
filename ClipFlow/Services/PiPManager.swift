import SwiftUI
import AVKit
import CoreImage

@Observable
final class PiPManager: NSObject, AVPictureInPictureControllerDelegate {
    var isActive = false
    var isAvailable = false

    private var pipController: AVPictureInPictureController?
    private var displayLayer: AVSampleBufferDisplayLayer?
    private var displayLink: CADisplayLink?
    private var hostingView: UIView?
    private let imageRenderer = ImageRenderer()

    override init() {
        super.init()
        checkAvailability()
    }

    private func checkAvailability() {
        isAvailable = AVPictureInPictureController.isPictureInPictureSupported()
    }

    func setup(with view: UIView) {
        guard isAvailable else { return }

        hostingView = view

        let sampleLayer = AVSampleBufferDisplayLayer()
        sampleLayer.videoGravity = .resizeAspect
        sampleLayer.frame = CGRect(x: 0, y: 0, width: 200, height: 300)
        view.layer.addSublayer(sampleLayer)

        let contentSource = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: sampleLayer,
            playbackDelegate: self
        )

        let controller = AVPictureInPictureController(contentSource: contentSource)
        controller.delegate = self
        controller.canStartPictureInPictureAutomaticallyFromInline = true

        pipController = controller
        displayLayer = sampleLayer
    }

    func toggle() {
        guard let controller = pipController else { return }
        if controller.isPictureInPictureActive {
            controller.stopPictureInPicture()
        } else {
            controller.startPictureInPicture()
        }
    }

    func renderFrame() {
        guard let displayLayer, pipController?.isPictureInPictureActive == true else { return }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 300))
        let image = renderer.image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 200, height: 300))

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.white
            ]
            let clipText = ClipboardStore.shared.latestItem?.preview ?? "ClipFlow"
            (clipText as NSString).draw(at: CGPoint(x: 16, y: 60), withAttributes: attributes)

            let countAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.gray
            ]
            let count = "\(ClipboardStore.shared.allItems.count) éléments"
            (count as NSString).draw(at: CGPoint(x: 16, y: 100), withAttributes: countAttr)
        }

        guard let pixelBuffer = image.toCVPixelBuffer() else { return }
        guard let sampleBuffer = createSampleBuffer(from: pixelBuffer) else { return }
        displayLayer.enqueue(sampleBuffer)
    }

    private func createSampleBuffer(from pixelBuffer: CVPixelBuffer) -> CMSampleBuffer? {
        var formatDescription: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )
        guard let formatDesc = formatDescription else { return nil }

        let now = CMClockGetTime(CMClockGetHostTimeClock())
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 15),
            presentationTimeStamp: now,
            decodeTimeStamp: now
        )

        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDesc,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
        return sampleBuffer
    }

    func startRendering() {
        displayLink = CADisplayLink(target: self, selector: #selector(renderTick))
        displayLink?.preferredFramesPerSecond = 10
        displayLink?.add(to: .current, forMode: .common)
    }

    @objc private func renderTick() {
        renderFrame()
    }

    func stopRendering() {
        displayLink?.invalidate()
        displayLink = nil
    }

    // MARK: - AVPictureInPictureControllerDelegate

    func pictureInPictureControllerDidStartPictureInPicture(_ controller: AVPictureInPictureController) {
        isActive = true
        startRendering()
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        isActive = false
        stopRendering()
    }

    func pictureInPictureController(_ controller: AVPictureInPictureController,
                                     failedToStartPictureInPictureWithError error: Error) {
        isActive = false
    }
}

// MARK: - UIImage → CVPixelBuffer

extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let width = 200
        let height = 300

        var pixelBuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        CVPixelBufferCreate(
            kCFAllocatorDefault, width, height,
            kCVPixelFormatType_32ARGB, attrs as CFDictionary,
            &pixelBuffer
        )
        guard let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, .init(rawValue: 0))
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width, height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        guard let cgContext = context, let cgImage = self.cgImage else {
            CVPixelBufferUnlockBaseAddress(buffer, .init(rawValue: 0))
            return nil
        }
        cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(buffer, .init(rawValue: 0))
        return buffer
    }
}
