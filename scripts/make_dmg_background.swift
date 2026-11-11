import AppKit

// Renders the DMG window background (1320x800 = 660x400pt @2x):
// navy gradient matching the app icon, title, subtitle, drag hint.

let width: CGFloat = 1320
let height: CGFloat = 800

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(width),
    pixelsHigh: Int(height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!
let nsCtx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = nsCtx
let ctx = nsCtx.cgContext

// Background: diagonal navy gradient (same palette as the icon).
let bg = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        CGColor(srgbRed: 0.07, green: 0.16, blue: 0.32, alpha: 1),
        CGColor(srgbRed: 0.13, green: 0.30, blue: 0.52, alpha: 1),
    ] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: 0), end: CGPoint(x: width, y: height), options: [])

// Helper: draw centered text. `topY` is distance from the top in pixels
// (context is y-up, so convert).
func drawCentered(_ text: String, font: NSFont, color: NSColor, topY: CGFloat, tracking: CGFloat = 0) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .kern: tracking,
    ]
    let str = NSAttributedString(string: text, attributes: attrs)
    let textSize = str.size()
    let textX = (width - textSize.width) / 2
    let textY = height - topY - textSize.height
    str.draw(at: CGPoint(x: textX, y: textY))
}


drawCentered("Twenty20", font: .systemFont(ofSize: 120, weight: .bold), color: .white, topY: 190)
drawCentered("rest your eyes — the 20-20-20 rule", font: .systemFont(ofSize: 40, weight: .regular), color: NSColor(white: 1, alpha: 0.72), topY: 350)
drawCentered("drag the app to Applications", font: .systemFont(ofSize: 32, weight: .medium), color: NSColor(white: 1, alpha: 0.55), topY: 640)

guard let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("failed to render background\n".data(using: .utf8)!)
    exit(1)
}
let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Twenty20-dmg-bg.png"
try png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
