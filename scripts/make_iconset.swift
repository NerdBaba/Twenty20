import AppKit

// Builds the .iconset from Assets/icon-alpha.png (artwork with transparent
// background, produced by remove_black_bg.swift). Each icon is the artwork
// composited over the navy gradient used across the app.
//
// Usage: swift scripts/make_iconset.swift <alpha.png> <outdir>

let srcPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Assets/icon-alpha.png"
let outDir = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "Twenty20.iconset"

guard let srcImage = NSImage(contentsOfFile: srcPath) else {
    FileHandle.standardError.write("cannot load \(srcPath)\n".data(using: .utf8)!)
    exit(1)
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

try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

for (name, px) in entries {
    let side = Int(px)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: side,
        pixelsHigh: side,
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

    // Navy gradient background (full-bleed; macOS masks to the squircle).
    let bg = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            CGColor(srgbRed: 0.07, green: 0.16, blue: 0.32, alpha: 1),
            CGColor(srgbRed: 0.13, green: 0.30, blue: 0.52, alpha: 1),
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: 0), end: CGPoint(x: side, y: side), options: [])

    // Artwork at 92% centered — the source already carries its own navy
    // background, which blends into this matching gradient; macOS masks
    // the result to the squircle.
    let artSide = CGFloat(side) * 0.92
    let artOrigin = CGPoint(x: (CGFloat(side) - artSide) / 2, y: (CGFloat(side) - artSide) / 2)
    // NSImage.draw already renders upright in the context's coordinate
    // space; the art rect is centered, so the y-origin doesn't matter.
    srcImage.draw(in: NSRect(x: artOrigin.x, y: artOrigin.y, width: artSide, height: artSide))

    guard let png = rep.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write("failed to render \(name)\n".data(using: .utf8)!)
        exit(1)
    }
    try png.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
}
print("wrote \(entries.count) icons to \(outDir)")
