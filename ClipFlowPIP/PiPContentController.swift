import UIKit
import AVKit

final class PiPContentController: UIViewController {
    private var pipController: AVPictureInPictureController?
    private var displayLayer: AVSampleBufferDisplayLayer?
    private var displayLink: CADisplayLink?
    private let store = ClipboardStore.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupPiP()
    }

    private func setupPiP() {
        let sampleLayer = AVSampleBufferDisplayLayer()
        sampleLayer.videoGravity = .resizeAspect
        sampleLayer.frame = view.bounds
        sampleLayer.backgroundColor = UIColor.clear.cgColor
        view.layer.addSublayer(sampleLayer)

        let contentSource = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: sampleLayer,
            playbackDelegate: self
        )

        let controller = AVPictureInPictureController(contentSource: contentSource)
        controller.delegate = self
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        self.pipController = controller
        self.displayLayer = sampleLayer
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pipController?.startPictureInPicture()
    }

    private func startRendering() {
        displayLink = CADisplayLink(target: self, selector: #selector(renderFrame))
        displayLink?.preferredFramesPerSecond = 8
        displayLink?.add(to: .current, forMode: .common)
    }

    private func stopRendering() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func renderFrame() {
        guard let displayLayer, pipController?.isPictureInPictureActive == true else { return }

        let w: CGFloat = 200
        let h: CGFloat = 300
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        let image = renderer.image { ctx in
            let c = ctx.cgContext

            // Clip to rounded rect
            let clipPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: w, height: h),
                                        byRoundingCorners: .allCorners,
                                        cornerRadii: CGSize(width: 24, height: 24)).cgPath
            c.addPath(clipPath)
            c.clip()

            // Dark gradient background
            let bgColors = [
                UIColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1).cgColor,
                UIColor(red: 0.02, green: 0.02, blue: 0.03, alpha: 1).cgColor
            ]
            drawGradient(c, colors: bgColors, rect: CGRect(x: 0, y: 0, width: w, height: h))

            // Subtle glass overlay
            c.setFillColor(UIColor.white.withAlphaComponent(0.03).cgColor)
            c.fill(CGRect(x: 0, y: 0, width: w, height: h * 0.4))

            // Border
            c.setStrokeColor(UIColor.white.withAlphaComponent(0.08).cgColor)
            c.setLineWidth(1)
            c.addPath(clipPath)
            c.strokePath()

            // Orange accent line at top
            c.setFillColor(UIColor.systemOrange.cgColor)
            c.fill(CGRect(x: 0, y: 0, width: w, height: 2.5))

            // Header
            let headerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            ("ClipFlow" as NSString).draw(at: CGPoint(x: 14, y: 12), withAttributes: headerAttr)

            // Dot indicator
            c.setFillColor(UIColor.systemOrange.cgColor)
            c.fillEllipse(in: CGRect(x: w - 28, y: 15, width: 6, height: 6))
            c.setFillColor(UIColor.systemOrange.withAlphaComponent(0.2).cgColor)
            c.fillEllipse(in: CGRect(x: w - 30, y: 13, width: 10, height: 10))

            // Count label
            let countStr = "\(store.allItems.count)"
            let countAttr: [NSAttributedString.Key: Any] = [
                .font: roundedFont(ofSize: 10, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.3)
            ]
            (countStr as NSString).draw(at: CGPoint(x: w - 56, y: 14), withAttributes: countAttr)

            c.setStrokeColor(UIColor.white.withAlphaComponent(0.06).cgColor)
            c.setLineWidth(0.5)
            c.move(to: CGPoint(x: 14, y: 36))
            c.addLine(to: CGPoint(x: w - 14, y: 36))
            c.strokePath()

            if let latest = store.latestItem {
                // Type icon in colored circle
                let iconConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
                let typeColor = typeUIColor(latest.type)
                if let icon = UIImage(systemName: latest.type.icon, withConfiguration: iconConfig)?
                    .withTintColor(typeColor, renderingMode: .alwaysOriginal) {
                    icon.draw(in: CGRect(x: 16, y: 56, width: 22, height: 22))
                }

                // Type label
                let typeLabelAttr: [NSAttributedString.Key: Any] = [
                    .font: roundedFont(ofSize: 9, weight: .semibold),
                    .foregroundColor: typeColor
                ]
                (latest.type.rawValue.uppercased() as NSString).draw(
                    at: CGPoint(x: 44, y: 60),
                    withAttributes: typeLabelAttr
                )

                // Timestamp
                let tsStr = latest.timestamp.formatted(date: .omitted, time: .shortened)
                let tsAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.25)
                ]
                (tsStr as NSString).draw(at: CGPoint(x: w - 52, y: 60), withAttributes: tsAttr)

                // Content text
                let paraStyle = NSMutableParagraphStyle()
                paraStyle.lineSpacing = 3
                let contentAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.75),
                    .paragraphStyle: paraStyle
                ]
                (latest.preview as NSString).draw(
                    in: CGRect(x: 16, y: 86, width: 168, height: 100),
                    withAttributes: contentAttr
                )

                // Bottom hint bar
                c.setFillColor(UIColor.white.withAlphaComponent(0.04).cgColor)
                let hintRect = CGRect(x: 0, y: h - 32, width: w, height: 32)
                c.fill(hintRect)

                let hintAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.2)
                ]
                ("Tap pour ouvrir ClipFlow" as NSString).draw(
                    at: CGPoint(x: 14, y: h - 22),
                    withAttributes: hintAttr
                )

                let sipAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9, weight: .medium),
                    .foregroundColor: UIColor.systemOrange.withAlphaComponent(0.4)
                ]
                ("Copier" as NSString).draw(at: CGPoint(x: w - 52, y: h - 22), withAttributes: sipAttr)
            } else {
                // Empty state
                let emptyIconConf = UIImage.SymbolConfiguration(pointSize: 32, weight: .light)
                if let icon = UIImage(systemName: "doc.on.clipboard", withConfiguration: emptyIconConf)?
                    .withTintColor(.white.withAlphaComponent(0.08), renderingMode: .alwaysOriginal) {
                    icon.draw(in: CGRect(x: w/2 - 16, y: h/2 - 36, width: 32, height: 32))
                }

                let emptyAttr: [NSAttributedString.Key: Any] = [
                    .font: roundedFont(ofSize: 13, weight: .medium),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.2)
                ]
                ("En attente..." as NSString).draw(at: CGPoint(x: 60, y: h/2 + 8), withAttributes: emptyAttr)
            }
        }

        guard let pixelBuffer = image.toCVPixelBuffer() else { return }
        guard let sampleBuffer = createSampleBuffer(from: pixelBuffer) else { return }
        displayLayer.enqueue(sampleBuffer)
    }

    private func drawGradient(_ c: CGContext, colors: [CGColor], rect: CGRect) {
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: [0, 1]
        ) else { return }
        c.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: rect.height), options: [])
    }

    private func typeUIColor(_ type: ClipType) -> UIColor {
        switch type {
        case .text: return .systemBlue
        case .url: return .systemGreen
        case .email: return .systemPurple
        case .phone: return .orange
        case .code: return .systemPink
        case .image: return .cyan
        }
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
        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 10),
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
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )
        return sampleBuffer
    }
}

extension PiPContentController: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStartPictureInPicture(_: AVPictureInPictureController) { startRendering() }
    func pictureInPictureControllerDidStopPictureInPicture(_: AVPictureInPictureController) { stopRendering() }
}

extension PiPContentController: AVPictureInPictureSampleBufferPlaybackDelegate {
    func pictureInPictureController(_: AVPictureInPictureController, setPlaying _: Bool) {}
    func pictureInPictureControllerTimeRangeForPlayback(_: AVPictureInPictureController) -> CMTimeRange {
        CMTimeRange(start: .zero, duration: .positiveInfinity)
    }
    func pictureInPictureControllerIsPlaybackPaused(_: AVPictureInPictureController) -> Bool { false }
}

private func roundedFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
    let base = UIFont.systemFont(ofSize: size, weight: weight)
    let descriptor = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
    return UIFont(descriptor: descriptor, size: size)
}
