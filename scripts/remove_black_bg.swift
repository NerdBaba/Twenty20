import AppKit

// One-off tool: removes the edge-connected black background from
// Assets/icon-source.png via flood fill, writes Assets/icon-alpha.png.
// Safe to re-run if the source art changes.
//
// Usage: swift scripts/remove_black_bg.swift [src.png] [out.png]

let srcPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Assets/icon-source.png"
let outPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "Assets/icon-alpha.png"

let img = NSImage(contentsOfFile: srcPath)!
let width = Int(img.size.width)
let height = Int(img.size.height)

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
img.draw(in: NSRect(x: 0, y: 0, width: width, height: height))
NSGraphicsContext.restoreGraphicsState()

guard let data = rep.bitmapData else {
    FileHandle.standardError.write("no bitmap data\n".data(using: .utf8)!)
    exit(1)
}
let px = data
let rowBytes = rep.bytesPerRow

// "Dark" = all three color bytes below threshold. Byte order doesn't matter
// for this check (black is black in RGBA or BGRA).
let darkThreshold: UInt8 = 48
func isDark(_ col: Int, _ row: Int) -> Bool {
    let offset = row * rowBytes + col * 4
    return px[offset] < darkThreshold && px[offset + 1] < darkThreshold && px[offset + 2] < darkThreshold
}

// BFS flood fill from every dark border pixel (4-connectivity).
var visited = [UInt8](repeating: 0, count: width * height)
var queue: [(Int, Int)] = []
queue.reserveCapacity(width * height / 4)

func enqueue(_ col: Int, _ row: Int) {
    let index = row * width + col
    if visited[index] == 0 && isDark(col, row) {
        visited[index] = 1
        queue.append((col, row))
    }
}
for col in 0..<width { enqueue(col, 0); enqueue(col, height - 1) }
for row in 0..<height { enqueue(0, row); enqueue(width - 1, row) }

var head = 0
while head < queue.count {
    let (col, row) = queue[head]
    head += 1
    if col > 0 { enqueue(col - 1, row) }
    if col < width - 1 { enqueue(col + 1, row) }
    if row > 0 { enqueue(col, row - 1) }
    if row < height - 1 { enqueue(col, row + 1) }
}

// Zero all four bytes for visited pixels — order-agnostic full transparency.
var cleared = 0
for row in 0..<height {
    for col in 0..<width where visited[row * width + col] == 1 {
        let offset = row * rowBytes + col * 4
        px[offset] = 0; px[offset + 1] = 0; px[offset + 2] = 0; px[offset + 3] = 0
        cleared += 1
    }
}

guard let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("png encode failed\n".data(using: .utf8)!)
    exit(1)
}
try png.write(to: URL(fileURLWithPath: outPath))
print("removed \(cleared) bg pixels -> \(outPath)")
