// Renders the GPT Voice DMG window background: a standard Finder window, 760 x 500 points.
// Light paper in the app's canvas color, the WaveMark and wordmark at the top, one instruction line,
// and an arrow between the app icon (210, 255) and the Applications link (550, 255).
// Finder draws the icons and their labels; this image leaves that area empty.
// All text is the app's bundled FT Regola Neue display face; no system font is rasterized.
// Usage: swift docs/installer/render-background.swift FONT_DIRECTORY OUTPUT_DIRECTORY
// Writes background.png (760 x 500, 72 dpi) and background@2x.png (1520 x 1000, 144 dpi).
import AppKit
import CoreText

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    FileHandle.standardError.write(Data("Usage: render-background.swift FONT_DIRECTORY OUTPUT_DIRECTORY\n".utf8))
    exit(2)
}
let fontDirectory = URL(fileURLWithPath: arguments[1])
let outputDirectory = URL(fileURLWithPath: arguments[2])

/// Loads one bundled static face by PostScript name, failing rather than falling back to another font.
func bundledFont(_ name: String, size: CGFloat) -> NSFont {
    let file = fontDirectory.appendingPathComponent("\(name).otf")
    CTFontManagerRegisterFontsForURL(file as CFURL, .process, nil)
    guard let font = NSFont(name: name, size: size), font.fontName == name else {
        FileHandle.standardError.write(Data("Could not load \(name) from \(file.path).\n".utf8))
        exit(1)
    }
    return font
}

let wordmarkFont = bundledFont("FTRegolaNeue-Semibold", size: 28)
let instructionFont = bundledFont("FTRegolaNeue-Medium", size: 15)
let footnoteFont = bundledFont("FTRegolaNeue-Regular", size: 12.5)

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

// AppPalette light roles: canvas #F4F4F3, ink #1C1C1E (graphite of the app icon).
let paperTop = color(0xF6F6F5)
let paperBottom = color(0xEFEFEE)
let ink = color(0x1C1C1E)
let secondaryInk = color(0x6E6E73)
let tertiaryInk = color(0x8E8E93)
let arrowInk = color(0x1C1C1E, alpha: 0.38)

let canvas = NSSize(width: 760, height: 500)
let appCenter = NSPoint(x: 210, y: 255)
let applicationsCenter = NSPoint(x: 550, y: 255)
let iconSize: CGFloat = 112

func centered(_ text: NSAttributedString, centerX: CGFloat, top: CGFloat) {
    let size = text.size()
    text.draw(at: NSPoint(x: centerX - size.width / 2, y: top))
}

/// Five rounded bars, the WaveMark proportions used by the app icon (0.26, 0.5, 0.7, 0.44, 0.22).
func drawWaveMark(in rect: NSRect) {
    let heights: [CGFloat] = [0.26, 0.5, 0.7, 0.44, 0.22]
    let barWidth = rect.width * 0.12
    let gap = (rect.width - barWidth * 5) / 4
    var x = rect.minX
    ink.setFill()
    for height in heights {
        let barHeight = rect.height * height / 0.7
        let bar = NSRect(x: x, y: rect.midY - barHeight / 2, width: barWidth, height: barHeight)
        NSBezierPath(roundedRect: bar, xRadius: barWidth / 2, yRadius: barWidth / 2).fill()
        x += barWidth + gap
    }
}

func drawBackground() {
    let bounds = NSRect(origin: .zero, size: canvas)
    NSGradient(starting: paperTop, ending: paperBottom)?.draw(in: bounds, angle: 90)

    // Header: WaveMark and wordmark as one centered group.
    let wordmark = NSAttributedString(string: "GPT Voice", attributes: [
        .font: wordmarkFont, .foregroundColor: ink, .kern: -0.4,
    ])
    let markSize = NSSize(width: 24, height: 24)
    let spacing: CGFloat = 11
    let wordmarkSize = wordmark.size()
    let groupWidth = markSize.width + spacing + wordmarkSize.width
    let groupLeft = canvas.width / 2 - groupWidth / 2
    let headerMidY: CGFloat = 76
    drawWaveMark(in: NSRect(x: groupLeft, y: headerMidY - markSize.height / 2,
                            width: markSize.width, height: markSize.height))
    let capCenterOffset = wordmarkFont.ascender - wordmarkFont.capHeight / 2
    wordmark.draw(at: NSPoint(x: groupLeft + markSize.width + spacing, y: headerMidY - capCenterOffset))

    let instruction = NSAttributedString(string: "Drag to Applications", attributes: [
        .font: instructionFont, .foregroundColor: secondaryInk,
    ])
    centered(instruction, centerX: canvas.width / 2, top: 106)

    // Arrow between the icons, clear of their 112-point frames.
    let clearance: CGFloat = 40
    let start = NSPoint(x: appCenter.x + iconSize / 2 + clearance, y: appCenter.y)
    let end = NSPoint(x: applicationsCenter.x - iconSize / 2 - clearance, y: applicationsCenter.y)
    arrowInk.setStroke()
    let shaft = NSBezierPath()
    shaft.lineWidth = 2
    shaft.lineCapStyle = .round
    shaft.move(to: start)
    shaft.line(to: NSPoint(x: end.x - 1, y: end.y))
    shaft.stroke()
    let head = NSBezierPath()
    head.lineWidth = 2
    head.lineCapStyle = .round
    head.lineJoinStyle = .round
    head.move(to: NSPoint(x: end.x - 9, y: end.y - 9))
    head.line(to: end)
    head.line(to: NSPoint(x: end.x - 9, y: end.y + 9))
    head.stroke()

    let footnote = NSAttributedString(string: "Then open GPT Voice from your Applications folder.", attributes: [
        .font: footnoteFont, .foregroundColor: tertiaryInk,
    ])
    centered(footnote, centerX: canvas.width / 2, top: 446)
}

func render(scale: Int, to url: URL) {
    let pixelsWide = Int(canvas.width) * scale
    let pixelsHigh = Int(canvas.height) * scale
    guard let space = CGColorSpace(name: CGColorSpace.sRGB),
          let cgContext = CGContext(data: nil, width: pixelsWide, height: pixelsHigh, bitsPerComponent: 8,
                                    bytesPerRow: 0, space: space,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        FileHandle.standardError.write(Data("Could not create the drawing context.\n".utf8))
        exit(1)
    }
    // Flipped, top-left origin in points, so layout reads in Finder's coordinates.
    cgContext.translateBy(x: 0, y: CGFloat(pixelsHigh))
    cgContext.scaleBy(x: CGFloat(scale), y: -CGFloat(scale))
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cgContext, flipped: true)
    drawBackground()
    NSGraphicsContext.restoreGraphicsState()

    guard let image = cgContext.makeImage() else {
        FileHandle.standardError.write(Data("Could not finish the image.\n".utf8))
        exit(1)
    }
    let bitmap = NSBitmapImageRep(cgImage: image)
    // Point size fixes the DPI (72 at 1x, 144 at 2x), so Finder shows both at 760 x 500 points.
    bitmap.size = canvas
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write(Data("Could not encode the PNG.\n".utf8))
        exit(1)
    }
    do {
        try png.write(to: url)
    } catch {
        FileHandle.standardError.write(Data("Could not write \(url.path): \(error.localizedDescription)\n".utf8))
        exit(1)
    }
}

try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
render(scale: 1, to: outputDirectory.appendingPathComponent("background.png"))
render(scale: 2, to: outputDirectory.appendingPathComponent("background@2x.png"))
