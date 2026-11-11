import AppKit

// Renders the Twenty20 app icon at every required .iconset size.
// Design: navy gradient field, white eye outline, amber iris with clock hands
// pointing at ~8:00 (the "20" in 20-20-20).
struct IconRenderer {
    let size: CGFloat

    /// Renders at exactly `size`×`size` pixels regardless of display scale.
    func render() -> NSBitmapImageRep {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size),
            pixelsHigh: Int(size),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        let ctx = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
        draw(in: ctx, size: size)
        return rep
    }

    private func draw(in ctx: CGContext, size side: CGFloat) {
        ctx.clear(CGRect(x: 0, y: 0, width: side, height: side))

        // Background: diagonal navy gradient.
        let bg = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                CGColor(srgbRed: 0.07, green: 0.16, blue: 0.32, alpha: 1),
                CGColor(srgbRed: 0.13, green: 0.30, blue: 0.52, alpha: 1),
            ] as CFArray,
            locations: [0, 1]
        )!
        ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: side), end: CGPoint(x: side, y: 0), options: [])

        // Subtle top highlight.
        let highlight = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.10),
                CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0),
            ] as CFArray,
            locations: [0, 0.55]
        )!
        ctx.saveGState()
        ctx.clip(to: CGRect(x: 0, y: side * 0.45, width: side, height: side * 0.55))
        ctx.drawLinearGradient(highlight, start: CGPoint(x: 0, y: side), end: CGPoint(x: 0, y: side * 0.45), options: [])
        ctx.restoreGState()

        // All icon geometry in unit space, y down from top.
        func pt(_ ux: CGFloat, _ uy: CGFloat) -> CGPoint {
            CGPoint(x: ux * side, y: (1 - uy) * side)
        }

        // Eye outline: two quadratic arcs meeting at the corners.
        let eye = CGMutablePath()
        eye.move(to: pt(0.16, 0.52))
        eye.addQuadCurve(to: pt(0.84, 0.52), control: pt(0.50, 0.16))
        eye.addQuadCurve(to: pt(0.16, 0.52), control: pt(0.50, 0.86))
        eye.closeSubpath()

        ctx.saveGState()
        ctx.setFillColor(CGColor(srgbRed: 0.96, green: 0.97, blue: 0.98, alpha: 1))
        ctx.addPath(eye)
        ctx.fillPath()
        ctx.setStrokeColor(CGColor(srgbRed: 0.55, green: 0.62, blue: 0.70, alpha: 0.9))
        ctx.setLineWidth(side * 0.018)
        ctx.addPath(eye)
        ctx.strokePath()
        ctx.restoreGState()

        // Iris: radial amber gradient with clock hands at ~8:00 / ~8:20.
        let irisCenter = pt(0.50, 0.52)
        let irisRadius = side * 0.21
        let iris = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                CGColor(srgbRed: 0.98, green: 0.78, blue: 0.35, alpha: 1),
                CGColor(srgbRed: 0.85, green: 0.52, blue: 0.16, alpha: 1),
            ] as CFArray,
            locations: [0, 1]
        )!
        ctx.saveGState()
        ctx.addEllipse(in: CGRect(x: irisCenter.x - irisRadius, y: irisCenter.y - irisRadius, width: irisRadius * 2, height: irisRadius * 2))
        ctx.clip()
        ctx.drawRadialGradient(iris, startCenter: irisCenter, startRadius: 0, endCenter: irisCenter, endRadius: irisRadius, options: [])

        let handColor = CGColor(srgbRed: 0.16, green: 0.20, blue: 0.28, alpha: 0.95)
        let handLen = irisRadius * 0.82
        ctx.setStrokeColor(handColor)
        ctx.setLineCap(.round)
        // Hour hand toward 8:00 (left-down in y-down coords).
        ctx.setLineWidth(side * 0.035)
        ctx.move(to: irisCenter)
        ctx.addLine(to: CGPoint(x: irisCenter.x - 0.5 * handLen * 0.55, y: irisCenter.y + 0.866 * handLen * 0.55))
        ctx.strokePath()
        // Minute hand toward ~8:20.
        ctx.setLineWidth(side * 0.022)
        ctx.move(to: irisCenter)
        ctx.addLine(to: CGPoint(x: irisCenter.x - 0.94 * handLen, y: irisCenter.y + 0.34 * handLen))
        ctx.strokePath()
        ctx.restoreGState()

        // Pupil.
        let pupilRadius = side * 0.085
        ctx.setFillColor(CGColor(srgbRed: 0.10, green: 0.12, blue: 0.18, alpha: 1))
        ctx.addEllipse(in: CGRect(x: irisCenter.x - pupilRadius, y: irisCenter.y - pupilRadius, width: pupilRadius * 2, height: pupilRadius * 2))
        ctx.fillPath()

        // Specular highlight on the eye.
        ctx.saveGState()
        ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.5))
        ctx.addEllipse(in: CGRect(x: side * 0.30, y: side * 0.30, width: side * 0.10, height: side * 0.055))
        ctx.fillPath()
        ctx.restoreGState()
    }
}

// iconset requirements: (filename, pixel size)
let entries: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Twenty20.iconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

for (name, px) in entries {
    let rep = IconRenderer(size: px).render()
    guard let png = rep.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write("failed to render \(name)\n".data(using: .utf8)!)
        exit(1)
    }
    try png.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
}
print("wrote \(entries.count) icons to \(outDir)")
