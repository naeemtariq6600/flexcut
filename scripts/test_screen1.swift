import Cocoa

func hexColor(_ hex: String, alpha: CGFloat = 1.0) -> NSColor {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
    var rgb: UInt64 = 0
    Scanner(string: hexSanitized).scanHexInt64(&rgb)
    let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
    let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
    let b = CGFloat(rgb & 0x0000FF) / 255.0
    return NSColor(red: r, green: g, blue: b, alpha: alpha)
}

func rectFromTop(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, totalHeight: CGFloat = 1024) -> NSRect {
    return NSRect(x: x, y: totalHeight - y - height, width: width, height: height)
}

let origPath = "/Users/naeem/.gemini/antigravity/brain/d986efc7-c9ed-4c15-8f32-12b200ba8330/.user_uploaded/media_1794082841179_dee3d64f.jpg"
let vloggerPath = "/Users/naeem/Documents/Developer/Android/LibreCuts/screenshots_source/vlogger.jpg"

guard let origImage = NSImage(contentsOfFile: origPath),
      let vloggerImage = NSImage(contentsOfFile: vloggerPath) else {
    print("Error loading images")
    exit(1)
}

let appScreen = NSImage(size: NSSize(width: 460, height: 1024))
appScreen.lockFocus()

// 1. Draw base original UI
origImage.draw(in: NSRect(x: 0, y: 0, width: 460, height: 1024))

// 2. Video Player Area: container is x: 13, y: 112, w: 434, h: 580 (radius 18)
let cardRect = rectFromTop(x: 13, y: 112, width: 434, height: 580, totalHeight: 1024)
let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 18, yRadius: 18)

let ctx = NSGraphicsContext.current!.cgContext
ctx.saveGState()
cardPath.addClip()

// Fill card background
hexColor("#111116").setFill()
cardRect.fill()

// Draw vlogger in center (9:16 aspect ratio: w: 326, h: 580, x: 67, y: 112)
let videoRect = rectFromTop(x: 67, y: 112, width: 326, height: 580, totalHeight: 1024)
// Aspect fill vlogger
let vSize = vloggerImage.size
let scale = max(videoRect.width / vSize.width, videoRect.height / vSize.height)
let drawW = vSize.width * scale
let drawH = vSize.height * scale
let drawX = videoRect.midX - drawW / 2
let drawY = videoRect.midY - drawH / 2
vloggerImage.draw(in: NSRect(x: drawX, y: drawY, width: drawW, height: drawH))

// 3. Draw Timestamp Pill at bottom left of video
let timeRect = rectFromTop(x: 28, y: 642, width: 110, height: 32, totalHeight: 1024)
let timePath = NSBezierPath(roundedRect: timeRect, xRadius: 8, yRadius: 8)
hexColor("#000000", alpha: 0.75).setFill()
timePath.fill()

let timeFont = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
let timeStr = NSAttributedString(string: "00:05 / 00:15", attributes: [.font: timeFont, .foregroundColor: NSColor.white])
let tPoint = NSPoint(x: timeRect.midX - timeStr.size().width / 2, y: timeRect.midY - timeStr.size().height / 2)
timeStr.draw(at: tPoint)

// 4. Draw Fullscreen icon at bottom right of video
let fsRect = rectFromTop(x: 404, y: 642, width: 30, height: 30, totalHeight: 1024)
let fsPath = NSBezierPath(roundedRect: fsRect, xRadius: 6, yRadius: 6)
hexColor("#000000", alpha: 0.6).setFill()
fsPath.fill()

// Expand arrows symbol
let fsFont = NSFont.systemFont(ofSize: 16, weight: .bold)
let fsStr = NSAttributedString(string: "⛶", attributes: [.font: fsFont, .foregroundColor: NSColor.white])
fsStr.draw(at: NSPoint(x: fsRect.midX - fsStr.size().width / 2, y: fsRect.midY - fsStr.size().height / 2))

ctx.restoreGState()

// 5. Replace Timeline Filmstrip with real vlogger frames
// The track is at x: 85, y: 780, w: 320, h: 56
let trackRect = rectFromTop(x: 85, y: 780, width: 320, height: 56, totalHeight: 1024)
let trackPath = NSBezierPath(roundedRect: trackRect, xRadius: 4, yRadius: 4)
ctx.saveGState()
trackPath.addClip()

let numFrames = 8
let frameW = trackRect.width / CGFloat(numFrames)
for i in 0..<numFrames {
    let fRect = NSRect(x: trackRect.minX + CGFloat(i) * frameW, y: trackRect.minY, width: frameW, height: trackRect.height)
    // Draw slice of vlogger
    let sScale = max(fRect.width / vSize.width, fRect.height / vSize.height)
    let sW = vSize.width * sScale
    let sH = vSize.height * sScale
    let sX = fRect.midX - sW / 2
    let sY = fRect.midY - sH / 2
    vloggerImage.draw(in: NSRect(x: sX, y: sY, width: sW, height: sH))
    
    // 1px separator
    hexColor("#000000", alpha: 0.5).setStroke()
    let sep = NSBezierPath()
    sep.move(to: NSPoint(x: fRect.maxX, y: fRect.minY))
    sep.line(to: NSPoint(x: fRect.maxX, y: fRect.maxY))
    sep.lineWidth = 1.0
    sep.stroke()
}
ctx.restoreGState()

// 6. Draw clean audio track at x: 85, y: 846, w: 365, h: 52
let audioRect = rectFromTop(x: 85, y: 846, width: 365, height: 52, totalHeight: 1024)
let audioPath = NSBezierPath(roundedRect: audioRect, xRadius: 4, yRadius: 4)
hexColor("#43A047").setFill()
audioPath.fill()

// Music icon & filename
let musicFont = NSFont.systemFont(ofSize: 13, weight: .bold)
let musicStr = NSAttributedString(string: "♪  Summer_Vibes.mp3", attributes: [.font: musicFont, .foregroundColor: NSColor.white])
musicStr.draw(at: NSPoint(x: audioRect.minX + 10, y: audioRect.midY - musicStr.size().height / 2))

// Waveform lines on audio track
let waveStartX = audioRect.minX + 170
let waveEndX = audioRect.maxX - 10
let waveHeights: [CGFloat] = [8, 14, 22, 18, 26, 32, 28, 18, 24, 30, 16, 12, 26, 34, 20, 14, 28, 30, 22, 16, 24, 18, 10]
let stepX = (waveEndX - waveStartX) / CGFloat(waveHeights.count)

for (idx, h) in waveHeights.enumerated() {
    let wx = waveStartX + CGFloat(idx) * stepX
    let wPath = NSBezierPath()
    wPath.move(to: NSPoint(x: wx, y: audioRect.midY - h / 2))
    wPath.line(to: NSPoint(x: wx, y: audioRect.midY + h / 2))
    hexColor("#FFFFFF", alpha: 0.65).setStroke()
    wPath.lineWidth = 2.0
    wPath.stroke()
}

// 7. Draw Red/Pink Playhead needle at x: 230
let needleX: CGFloat = 230
let needlePath = NSBezierPath()
needlePath.move(to: NSPoint(x: needleX, y: 1024 - 765))
needlePath.line(to: NSPoint(x: needleX, y: 1024 - 905))
hexColor("#FF2E63").setStroke()
needlePath.lineWidth = 2.0
needlePath.stroke()

// Scrubber handle pill at top
let handleRect = rectFromTop(x: needleX - 7, y: 752, width: 14, height: 26, totalHeight: 1024)
let handlePath = NSBezierPath(roundedRect: handleRect, xRadius: 4, yRadius: 4)
hexColor("#FF2E63").setFill()
handlePath.fill()

appScreen.unlockFocus()

let rep = NSBitmapImageRep(data: appScreen.tiffRepresentation!)!
let pngData = rep.representation(using: .png, properties: [:])!
try! pngData.write(to: URL(fileURLWithPath: "/tmp/enhanced_screen1.png"))
print("Saved /tmp/enhanced_screen1.png successfully!")
