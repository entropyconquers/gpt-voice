// Renders the GPT Voice app icon to match the in-app WaveMark:
// a graphite tile with five rounded voice bars in soft white. Monochrome. Original paths only, no assets.
// Transparent canvas with the native macOS icon inset.
// Usage: swift scripts/generate-icon.swift OUTPUT.png [SIZE]
import AppKit

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    FileHandle.standardError.write(Data("Usage: generate-icon.swift OUTPUT.png [SIZE]\n".utf8))
    exit(2)
}
let output = URL(fileURLWithPath: arguments[1])
let size = arguments.count >= 3 ? CGFloat(Double(arguments[2]) ?? 1024) : 1024

guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                                    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
      let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    FileHandle.standardError.write(Data("Could not create the bitmap.\n".utf8))
    exit(1)
}

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

let graphiteTop = color(0x2A2A2D)
let graphiteBottom = color(0x1C1C1E)
let bar = color(0xECECEC)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

// macOS icon grid: the tile is inset about 10% from the canvas edge. The rest stays transparent.
let inset = size * 0.1
let tile = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
let tileRadius = tile.width * 0.225

let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
shadow.shadowOffset = NSSize(width: 0, height: -size * 0.01)
shadow.shadowBlurRadius = size * 0.02
shadow.set()
let tilePath = NSBezierPath(roundedRect: tile, xRadius: tileRadius, yRadius: tileRadius)
NSGradient(starting: graphiteTop, ending: graphiteBottom)?.draw(in: tilePath, angle: -90)
NSShadow().set()

// Five rounded bars, the same proportions as WaveMark (0.26, 0.5, 0.7, 0.44, 0.22 of the tile).
let heights: [CGFloat] = [0.26, 0.5, 0.7, 0.44, 0.22]
let barWidth = tile.width * 0.075
let gap = tile.width * 0.065
let totalWidth = barWidth * CGFloat(heights.count) + gap * CGFloat(heights.count - 1)
var x = tile.midX - totalWidth / 2
bar.setFill()
for height in heights {
    let barHeight = tile.height * height * 0.78
    let rect = NSRect(x: x, y: tile.midY - barHeight / 2, width: barWidth, height: barHeight)
    NSBezierPath(roundedRect: rect, xRadius: barWidth / 2, yRadius: barWidth / 2).fill()
    x += barWidth + gap
}

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("Could not encode the PNG.\n".utf8))
    exit(1)
}
do {
    try png.write(to: output)
} catch {
    FileHandle.standardError.write(Data("Could not write \(output.path): \(error.localizedDescription)\n".utf8))
    exit(1)
}
