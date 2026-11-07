import Cocoa

let canvasWidth: CGFloat = 1080
let canvasHeight: CGFloat = 2400

func rectFromTop(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, totalHeight: CGFloat = canvasHeight) -> NSRect {
    return NSRect(x: x, y: totalHeight - y - height, width: width, height: height)
}

func hexColor(_ hex: String, alpha: CGFloat = 1.0) -> NSColor {
    let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
    var rgb: UInt64 = 0
    Scanner(string: hexSanitized).scanHexInt64(&rgb)
    let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
    let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
    let b = CGFloat(rgb & 0x0000FF) / 255.0
    return NSColor(red: r, green: g, blue: b, alpha: alpha)
}

func drawLinearGradient(colors: [NSColor], start: CGPoint, end: CGPoint, context: CGContext) {
    let cgColors = colors.map { $0.cgColor } as CFArray
    let space = CGColorSpaceCreateDeviceRGB()
    if let gradient = CGGradient(colorsSpace: space, colors: cgColors, locations: nil) {
        context.drawLinearGradient(gradient, start: start, end: end, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }
}

func drawRadialGlow(center: CGPoint, radius: CGFloat, color: NSColor, context: CGContext) {
    context.saveGState()
    let colors = [color.cgColor, color.withAlphaComponent(0.0).cgColor] as CFArray
    let space = CGColorSpaceCreateDeviceRGB()
    if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0.0, 1.0]) {
        context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [.drawsAfterEndLocation])
    }
    context.restoreGState()
}

func drawCategoryBadge(text: String, x: CGFloat, y: CGFloat, height: CGFloat = 52) {
    let font = NSFont.systemFont(ofSize: 22, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: hexColor("#FF2E63")
    ]
    let attrStr = NSAttributedString(string: text, attributes: attrs)
    let textWidth = attrStr.size().width
    let badgeWidth = textWidth + 44
    let badgeRect = rectFromTop(x: x, y: y, width: badgeWidth, height: height)
    
    let path = NSBezierPath(roundedRect: badgeRect, xRadius: height / 2, yRadius: height / 2)
    hexColor("#FF2E63", alpha: 0.15).setFill()
    path.fill()
    
    hexColor("#FF2E63", alpha: 0.45).setStroke()
    path.lineWidth = 1.5
    path.stroke()
    
    let textPoint = NSPoint(x: badgeRect.midX - textWidth / 2, y: badgeRect.midY - attrStr.size().height / 2 + 1)
    attrStr.draw(at: textPoint)
}

func drawHeader(badge: String, title: String, subtitle: String, context: CGContext) {
    let fontBadge = NSFont.systemFont(ofSize: 22, weight: .bold)
    let attrBadge = NSAttributedString(string: badge, attributes: [.font: fontBadge, .foregroundColor: hexColor("#FF2E63")])
    let bWidth = attrBadge.size().width + 44
    let bX = (canvasWidth - bWidth) / 2
    drawCategoryBadge(text: badge, x: bX, y: 130, height: 52)
    
    let titleFont = NSFont.systemFont(ofSize: 74, weight: .heavy)
    let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: titleFont,
        .foregroundColor: NSColor.white
    ]
    let titleStr = NSAttributedString(string: title, attributes: titleAttrs)
    let titleRect = rectFromTop(x: 40, y: 205, width: canvasWidth - 80, height: 95)
    
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -4), blur: 16, color: NSColor.black.withAlphaComponent(0.6).cgColor)
    let titleX = (canvasWidth - titleStr.size().width) / 2
    titleStr.draw(at: NSPoint(x: titleX, y: titleRect.midY - titleStr.size().height / 2))
    context.restoreGState()
    
    let subFont = NSFont.systemFont(ofSize: 34, weight: .medium)
    let subAttrs: [NSAttributedString.Key: Any] = [
        .font: subFont,
        .foregroundColor: hexColor("#94A3B8")
    ]
    let subStr = NSAttributedString(string: subtitle, attributes: subAttrs)
    let subRect = rectFromTop(x: 40, y: 310, width: canvasWidth - 80, height: 50)
    let subX = (canvasWidth - subStr.size().width) / 2
    subStr.draw(at: NSPoint(x: subX, y: subRect.midY - subStr.size().height / 2))
}

func drawFloatingBadge(icon: String, text: String, x: CGFloat, y: CGFloat, width: CGFloat = 380, height: CGFloat = 78, context: CGContext) {
    let badgeRect = rectFromTop(x: x, y: y, width: width, height: height)
    
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -14), blur: 28, color: NSColor.black.withAlphaComponent(0.70).cgColor)
    
    let path = NSBezierPath(roundedRect: badgeRect, xRadius: height / 2, yRadius: height / 2)
    hexColor("#151824", alpha: 0.94).setFill()
    path.fill()
    context.restoreGState()
    
    hexColor("#FFFFFF", alpha: 0.18).setStroke()
    path.lineWidth = 1.5
    path.stroke()
    
    let innerPath = NSBezierPath(roundedRect: badgeRect.insetBy(dx: 1.5, dy: 1.5), xRadius: (height - 3) / 2, yRadius: (height - 3) / 2)
    hexColor("#FF2E63", alpha: 0.22).setStroke()
    innerPath.lineWidth = 1.0
    innerPath.stroke()
    
    let iconFont = NSFont.systemFont(ofSize: 32)
    let textFont = NSFont.systemFont(ofSize: 28, weight: .bold)
    
    let iconStr = NSAttributedString(string: icon, attributes: [.font: iconFont])
    let textStr = NSAttributedString(string: text, attributes: [.font: textFont, .foregroundColor: NSColor.white])
    
    let iconWidth = iconStr.size().width
    let totalContentWidth = iconWidth + 14 + textStr.size().width
    let startX = badgeRect.midX - totalContentWidth / 2
    
    iconStr.draw(at: NSPoint(x: startX, y: badgeRect.midY - iconStr.size().height / 2))
    textStr.draw(at: NSPoint(x: startX + iconWidth + 14, y: badgeRect.midY - textStr.size().height / 2))
}

func drawPhoneMockup(screenImage: NSImage, targetRect: NSRect, context: CGContext) {
    let chassisRect = targetRect
    let cornerRadius: CGFloat = 54
    let bezelThickness: CGFloat = 14
    let screenRadius: CGFloat = cornerRadius - bezelThickness
    
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -30), blur: 50, color: NSColor.black.withAlphaComponent(0.85).cgColor)
    let chassisPath = NSBezierPath(roundedRect: chassisRect, xRadius: cornerRadius, yRadius: cornerRadius)
    hexColor("#181924").setFill()
    chassisPath.fill()
    context.restoreGState()
    
    hexColor("#353748").setStroke()
    chassisPath.lineWidth = 2.0
    chassisPath.stroke()
    
    let rimPath = NSBezierPath(roundedRect: chassisRect.insetBy(dx: 1, dy: 1), xRadius: cornerRadius - 1, yRadius: cornerRadius - 1)
    hexColor("#505470", alpha: 0.35).setStroke()
    rimPath.lineWidth = 1.0
    rimPath.stroke()
    
    let screenRect = chassisRect.insetBy(dx: bezelThickness, dy: bezelThickness)
    let screenPath = NSBezierPath(roundedRect: screenRect, xRadius: screenRadius, yRadius: screenRadius)
    
    context.saveGState()
    screenPath.addClip()
    
    screenImage.draw(in: screenRect)
    
    let holeWidth: CGFloat = 84
    let holeHeight: CGFloat = 24
    let holeRect = NSRect(x: screenRect.midX - holeWidth / 2, y: screenRect.maxY - 34, width: holeWidth, height: holeHeight)
    let holePath = NSBezierPath(roundedRect: holeRect, xRadius: holeHeight / 2, yRadius: holeHeight / 2)
    hexColor("#08080C").setFill()
    holePath.fill()
    
    let lensRect = NSRect(x: holeRect.minX + 16, y: holeRect.midY - 4, width: 8, height: 8)
    let lensPath = NSBezierPath(ovalIn: lensRect)
    hexColor("#1B2A40").setFill()
    lensPath.fill()
    
    let sheenPath = NSBezierPath()
    sheenPath.move(to: NSPoint(x: screenRect.minX, y: screenRect.maxY))
    sheenPath.line(to: NSPoint(x: screenRect.minX + 260, y: screenRect.maxY))
    sheenPath.line(to: NSPoint(x: screenRect.minX, y: screenRect.maxY - 500))
    sheenPath.close()
    hexColor("#FFFFFF", alpha: 0.035).setFill()
    sheenPath.fill()
    
    context.restoreGState()
    
    hexColor("#000000", alpha: 0.4).setStroke()
    screenPath.lineWidth = 1.5
    screenPath.stroke()
}

// Aspect fill helper
func drawImageAspectFill(image: NSImage, in targetRect: NSRect) {
    let imgSize = image.size
    let scale = max(targetRect.width / imgSize.width, targetRect.height / imgSize.height)
    let drawW = imgSize.width * scale
    let drawH = imgSize.height * scale
    let drawX = targetRect.midX - drawW / 2
    let drawY = targetRect.midY - drawH / 2
    image.draw(in: NSRect(x: drawX, y: drawY, width: drawW, height: drawH))
}

// Draw standard video player card with photo, timestamp, and expand icon
func drawVideoPlayerCard(photo: NSImage, in cardRect: NSRect, timeText: String = "00:05 / 00:15", overlayAction: ((CGContext, NSRect) -> Void)? = nil) {
    let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 18, yRadius: 18)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.saveGState()
    cardPath.addClip()
    
    // Background of card
    hexColor("#111116").setFill()
    cardRect.fill()
    
    // 9:16 Video in center (w: 326, h: 580)
    let videoRect = NSRect(x: cardRect.minX + 54, y: cardRect.minY, width: 326, height: cardRect.height)
    drawImageAspectFill(image: photo, in: videoRect)
    
    // Custom overlay if any (doodle, crop frame, subtitles)
    overlayAction?(ctx, videoRect)
    
    // Timestamp pill
    let timeRect = NSRect(x: cardRect.minX + 16, y: cardRect.minY + 16, width: 110, height: 32)
    let timePath = NSBezierPath(roundedRect: timeRect, xRadius: 8, yRadius: 8)
    hexColor("#000000", alpha: 0.75).setFill()
    timePath.fill()
    
    let timeFont = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
    let timeStr = NSAttributedString(string: timeText, attributes: [.font: timeFont, .foregroundColor: NSColor.white])
    let tPoint = NSPoint(x: timeRect.midX - timeStr.size().width / 2, y: timeRect.midY - timeStr.size().height / 2)
    timeStr.draw(at: tPoint)
    
    // Fullscreen icon
    let fsRect = NSRect(x: cardRect.maxX - 44, y: cardRect.minY + 16, width: 30, height: 30)
    let fsPath = NSBezierPath(roundedRect: fsRect, xRadius: 6, yRadius: 6)
    hexColor("#000000", alpha: 0.6).setFill()
    fsPath.fill()
    
    let fsFont = NSFont.systemFont(ofSize: 16, weight: .bold)
    let fsStr = NSAttributedString(string: "⛶", attributes: [.font: fsFont, .foregroundColor: NSColor.white])
    fsStr.draw(at: NSPoint(x: fsRect.midX - fsStr.size().width / 2, y: fsRect.midY - fsStr.size().height / 2))
    
    ctx.restoreGState()
}

// Replace timeline filmstrip with thumbnails
func drawTimelineFilmstrip(photo: NSImage, trackRect: NSRect, numFrames: Int = 8) {
    let ctx = NSGraphicsContext.current!.cgContext
    let trackPath = NSBezierPath(roundedRect: trackRect, xRadius: 4, yRadius: 4)
    ctx.saveGState()
    trackPath.addClip()
    
    let frameW = trackRect.width / CGFloat(numFrames)
    for i in 0..<numFrames {
        let fRect = NSRect(x: trackRect.minX + CGFloat(i) * frameW, y: trackRect.minY, width: frameW, height: trackRect.height)
        drawImageAspectFill(image: photo, in: fRect)
        
        hexColor("#000000", alpha: 0.5).setStroke()
        let sep = NSBezierPath()
        sep.move(to: NSPoint(x: fRect.maxX, y: fRect.minY))
        sep.line(to: NSPoint(x: fRect.maxX, y: fRect.maxY))
        sep.lineWidth = 1.0
        sep.stroke()
    }
    ctx.restoreGState()
}

// -------------------------------------------------------------
// APP SCREENS GENERATORS
// -------------------------------------------------------------

// Screen 1: Main Video Editor
func buildAppScreen1(orig: NSImage, vlogger: NSImage) -> NSImage {
    let screen = NSImage(size: NSSize(width: 460, height: 1024))
    screen.lockFocus()
    orig.draw(in: NSRect(x: 0, y: 0, width: 460, height: 1024))
    
    let cardRect = rectFromTop(x: 13, y: 112, width: 434, height: 580, totalHeight: 1024)
    drawVideoPlayerCard(photo: vlogger, in: cardRect)
    
    let trackRect = rectFromTop(x: 85, y: 780, width: 320, height: 56, totalHeight: 1024)
    drawTimelineFilmstrip(photo: vlogger, trackRect: trackRect)
    
    let audioRect = rectFromTop(x: 85, y: 846, width: 365, height: 52, totalHeight: 1024)
    let audioPath = NSBezierPath(roundedRect: audioRect, xRadius: 4, yRadius: 4)
    hexColor("#43A047").setFill()
    audioPath.fill()
    
    let musicFont = NSFont.systemFont(ofSize: 13, weight: .bold)
    let musicStr = NSAttributedString(string: "♪  Summer_Vibes.mp3", attributes: [.font: musicFont, .foregroundColor: NSColor.white])
    musicStr.draw(at: NSPoint(x: audioRect.minX + 10, y: audioRect.midY - musicStr.size().height / 2))
    
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
    
    let needleX: CGFloat = 230
    let needlePath = NSBezierPath()
    needlePath.move(to: NSPoint(x: needleX, y: 1024 - 765))
    needlePath.line(to: NSPoint(x: needleX, y: 1024 - 905))
    hexColor("#FF2E63").setStroke()
    needlePath.lineWidth = 2.0
    needlePath.stroke()
    
    let handleRect = rectFromTop(x: needleX - 7, y: 752, width: 14, height: 26, totalHeight: 1024)
    let handlePath = NSBezierPath(roundedRect: handleRect, xRadius: 4, yRadius: 4)
    hexColor("#FF2E63").setFill()
    handlePath.fill()
    
    screen.unlockFocus()
    return screen
}

// Screen 2: Crop Aspect Ratio
func buildAppScreen2(orig: NSImage, fashion: NSImage) -> NSImage {
    let screen = NSImage(size: NSSize(width: 460, height: 1024))
    screen.lockFocus()
    orig.draw(in: NSRect(x: 0, y: 0, width: 460, height: 1024))
    
    let cardRect = rectFromTop(x: 13, y: 112, width: 434, height: 580, totalHeight: 1024)
    drawVideoPlayerCard(photo: fashion, in: cardRect) { ctx, videoRect in
        // Draw 9:16 safe zone / crop guide frame
        let cropRect = videoRect.insetBy(dx: 12, dy: 16)
        
        // Dashed grid
        let gridPath = NSBezierPath()
        // 1/3 horizontal lines
        let h1 = cropRect.minY + cropRect.height / 3
        let h2 = cropRect.minY + 2 * cropRect.height / 3
        gridPath.move(to: NSPoint(x: cropRect.minX, y: h1)); gridPath.line(to: NSPoint(x: cropRect.maxX, y: h1))
        gridPath.move(to: NSPoint(x: cropRect.minX, y: h2)); gridPath.line(to: NSPoint(x: cropRect.maxX, y: h2))
        // 1/3 vertical lines
        let v1 = cropRect.minX + cropRect.width / 3
        let v2 = cropRect.minX + 2 * cropRect.width / 3
        gridPath.move(to: NSPoint(x: v1, y: cropRect.minY)); gridPath.line(to: NSPoint(x: v1, y: cropRect.maxY))
        gridPath.move(to: NSPoint(x: v2, y: cropRect.minY)); gridPath.line(to: NSPoint(x: v2, y: cropRect.maxY))
        
        let pattern: [CGFloat] = [4, 4]
        gridPath.setLineDash(pattern, count: 2, phase: 0)
        hexColor("#FFFFFF", alpha: 0.28).setStroke()
        gridPath.lineWidth = 1.0
        gridPath.stroke()
        
        // Outer glowing crop border
        let borderPath = NSBezierPath(rect: cropRect)
        hexColor("#FF2E63", alpha: 0.75).setStroke()
        borderPath.lineWidth = 1.5
        borderPath.stroke()
        
        // Corner brackets
        let bracketLen: CGFloat = 20
        let cPath = NSBezierPath()
        // Top Left
        cPath.move(to: NSPoint(x: cropRect.minX, y: cropRect.maxY - bracketLen))
        cPath.line(to: NSPoint(x: cropRect.minX, y: cropRect.maxY))
        cPath.line(to: NSPoint(x: cropRect.minX + bracketLen, y: cropRect.maxY))
        // Top Right
        cPath.move(to: NSPoint(x: cropRect.maxX - bracketLen, y: cropRect.maxY))
        cPath.line(to: NSPoint(x: cropRect.maxX, y: cropRect.maxY))
        cPath.line(to: NSPoint(x: cropRect.maxX, y: cropRect.maxY - bracketLen))
        // Bottom Left
        cPath.move(to: NSPoint(x: cropRect.minX, y: cropRect.minY + bracketLen))
        cPath.line(to: NSPoint(x: cropRect.minX, y: cropRect.minY))
        cPath.line(to: NSPoint(x: cropRect.minX + bracketLen, y: cropRect.minY))
        // Bottom Right
        cPath.move(to: NSPoint(x: cropRect.maxX - bracketLen, y: cropRect.minY))
        cPath.line(to: NSPoint(x: cropRect.maxX, y: cropRect.minY))
        cPath.line(to: NSPoint(x: cropRect.maxX, y: cropRect.minY + bracketLen))
        
        hexColor("#FFFFFF").setStroke()
        cPath.lineWidth = 3.0
        cPath.stroke()
        
        // Aspect badge tag on top of crop frame
        let tagRect = NSRect(x: cropRect.midX - 70, y: cropRect.maxY - 34, width: 140, height: 26)
        let tagPath = NSBezierPath(roundedRect: tagRect, xRadius: 13, yRadius: 13)
        hexColor("#FF2E63").setFill()
        tagPath.fill()
        let tagStr = NSAttributedString(string: "9:16  TikTok • Reels", attributes: [.font: NSFont.systemFont(ofSize: 11, weight: .bold), .foregroundColor: NSColor.white])
        tagStr.draw(at: NSPoint(x: tagRect.midX - tagStr.size().width / 2, y: tagRect.midY - tagStr.size().height / 2))
    }
    
    // In bottom sheet: highlight 9:16 option (at x=160, y=890, w=62, h=62)
    let p916Rect = rectFromTop(x: 160, y: 890, width: 62, height: 62, totalHeight: 1024)
    let p916Path = NSBezierPath(roundedRect: p916Rect, xRadius: 12, yRadius: 12)
    hexColor("#FF2E63", alpha: 0.18).setFill()
    p916Path.fill()
    hexColor("#FF2E63").setStroke()
    p916Path.lineWidth = 2.0
    p916Path.stroke()
    
    // Draw icon inside
    let icRect = NSRect(x: p916Rect.midX - 10, y: p916Rect.midY - 14, width: 20, height: 28)
    let icPath = NSBezierPath(roundedRect: icRect, xRadius: 3, yRadius: 3)
    hexColor("#FF2E63").setStroke()
    icPath.lineWidth = 2.0
    icPath.stroke()
    
    // Text "9:16" below icon
    let txtRect = rectFromTop(x: 160, y: 960, width: 62, height: 18, totalHeight: 1024)
    let txtStr = NSAttributedString(string: "9:16", attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .bold), .foregroundColor: hexColor("#FF2E63")])
    txtStr.draw(at: NSPoint(x: txtRect.midX - txtStr.size().width / 2, y: txtRect.midY - txtStr.size().height / 2))
    
    screen.unlockFocus()
    return screen
}

// Screen 3: Smart Subtitles
func buildAppScreen3(orig: NSImage, speaker: NSImage) -> NSImage {
    let screen = NSImage(size: NSSize(width: 460, height: 1024))
    screen.lockFocus()
    orig.draw(in: NSRect(x: 0, y: 0, width: 460, height: 1024))
    
    let cardRect = rectFromTop(x: 13, y: 112, width: 434, height: 580, totalHeight: 1024)
    drawVideoPlayerCard(photo: speaker, in: cardRect) { ctx, videoRect in
        // Modern viral TikTok/Reels caption overlay
        let subPillRect = NSRect(x: videoRect.midX - 145, y: videoRect.minY + 90, width: 290, height: 50)
        let subPillPath = NSBezierPath(roundedRect: subPillRect, xRadius: 10, yRadius: 10)
        hexColor("#000000", alpha: 0.82).setFill()
        subPillPath.fill()
        
        hexColor("#FF2E63", alpha: 0.6).setStroke()
        subPillPath.lineWidth = 1.5
        subPillPath.stroke()
        
        // Multi-color stylized caption
        let subFont = NSFont.systemFont(ofSize: 14, weight: .heavy)
        let part1 = NSAttributedString(string: "How to edit videos ", attributes: [.font: subFont, .foregroundColor: NSColor.white])
        let part2 = NSAttributedString(string: "10x FASTER 🔥", attributes: [.font: subFont, .foregroundColor: hexColor("#FFDD00")])
        
        let totalW = part1.size().width + part2.size().width
        let sX = subPillRect.midX - totalW / 2
        let sY = subPillRect.midY - part1.size().height / 2
        
        part1.draw(at: NSPoint(x: sX, y: sY))
        part2.draw(at: NSPoint(x: sX + part1.size().width, y: sY))
    }
    
    screen.unlockFocus()
    return screen
}

// Screen 4: Handwriting / Doodle
func buildAppScreen4(orig: NSImage, dancer: NSImage) -> NSImage {
    let screen = NSImage(size: NSSize(width: 460, height: 1024))
    screen.lockFocus()
    orig.draw(in: NSRect(x: 0, y: 0, width: 460, height: 1024))
    
    let cardRect = rectFromTop(x: 13, y: 112, width: 434, height: 580, totalHeight: 1024)
    drawVideoPlayerCard(photo: dancer, in: cardRect) { ctx, videoRect in
        // Artistic neon glow doodle around the dancer
        ctx.saveGState()
        
        // 1. Neon glowing crown above dancer's head (at x: midX - 35..midX + 35, y: maxY - 110)
        let crownBaseY = videoRect.maxY - 115
        let crownMidX = videoRect.midX
        
        let crownPath = NSBezierPath()
        crownPath.move(to: NSPoint(x: crownMidX - 32, y: crownBaseY))
        crownPath.line(to: NSPoint(x: crownMidX - 36, y: crownBaseY + 28))
        crownPath.line(to: NSPoint(x: crownMidX - 14, y: crownBaseY + 12))
        crownPath.line(to: NSPoint(x: crownMidX, y: crownBaseY + 36))
        crownPath.line(to: NSPoint(x: crownMidX + 14, y: crownBaseY + 12))
        crownPath.line(to: NSPoint(x: crownMidX + 36, y: crownBaseY + 28))
        crownPath.line(to: NSPoint(x: crownMidX + 32, y: crownBaseY))
        crownPath.close()
        
        // Outer glow
        ctx.setShadow(offset: .zero, blur: 14, color: hexColor("#FF2E63", alpha: 0.95).cgColor)
        hexColor("#FF2E63", alpha: 0.9).setStroke()
        crownPath.lineWidth = 4.0
        crownPath.stroke()
        
        // Inner bright stroke
        hexColor("#FFE5EC").setStroke()
        crownPath.lineWidth = 2.0
        crownPath.stroke()
        
        // Crown little gem circles on tips
        for pt in [NSPoint(x: crownMidX - 36, y: crownBaseY + 28), NSPoint(x: crownMidX, y: crownBaseY + 36), NSPoint(x: crownMidX + 36, y: crownBaseY + 28)] {
            let dotRect = NSRect(x: pt.x - 3, y: pt.y - 3, width: 6, height: 6)
            hexColor("#FFFFFF").setFill()
            NSBezierPath(ovalIn: dotRect).fill()
        }
        
        // 2. Neon energy loops wrapping around dancer
        let spiralPath = NSBezierPath()
        spiralPath.move(to: NSPoint(x: crownMidX - 80, y: crownBaseY - 140))
        spiralPath.curve(to: NSPoint(x: crownMidX + 85, y: crownBaseY - 190), controlPoint1: NSPoint(x: crownMidX - 20, y: crownBaseY - 110), controlPoint2: NSPoint(x: crownMidX + 90, y: crownBaseY - 150))
        spiralPath.curve(to: NSPoint(x: crownMidX - 70, y: crownBaseY - 260), controlPoint1: NSPoint(x: crownMidX + 70, y: crownBaseY - 230), controlPoint2: NSPoint(x: crownMidX - 80, y: crownBaseY - 220))
        spiralPath.curve(to: NSPoint(x: crownMidX + 75, y: crownBaseY - 330), controlPoint1: NSPoint(x: crownMidX - 60, y: crownBaseY - 300), controlPoint2: NSPoint(x: crownMidX + 80, y: crownBaseY - 290))
        
        // Outer glow stroke
        ctx.setShadow(offset: .zero, blur: 16, color: hexColor("#FF007F", alpha: 0.95).cgColor)
        hexColor("#FF2E63").setStroke()
        spiralPath.lineWidth = 5.0
        spiralPath.stroke()
        
        // Core white/pink stroke
        hexColor("#FFFFFF").setStroke()
        spiralPath.lineWidth = 2.5
        spiralPath.stroke()
        
        // Sparkle stars around
        let stars = [
            NSPoint(x: crownMidX - 55, y: crownBaseY + 25),
            NSPoint(x: crownMidX + 58, y: crownBaseY + 20),
            NSPoint(x: crownMidX - 95, y: crownBaseY - 180),
            NSPoint(x: crownMidX + 95, y: crownBaseY - 240)
        ]
        for s in stars {
            let starStr = NSAttributedString(string: "✦", attributes: [.font: NSFont.systemFont(ofSize: 16, weight: .bold), .foregroundColor: hexColor("#FFFFFF")])
            starStr.draw(at: NSPoint(x: s.x - 8, y: s.y - 8))
        }
        
        ctx.restoreGState()
    }
    
    // Bottom handwriting panel: highlight pink color circle
    // Color circles are around y=950, pink circle is 4th circle at x=195
    let pinkCircleRect = rectFromTop(x: 184, y: 948, width: 34, height: 34, totalHeight: 1024)
    let ringPath = NSBezierPath(ovalIn: pinkCircleRect.insetBy(dx: -3, dy: -3))
    hexColor("#FFFFFF").setStroke()
    ringPath.lineWidth = 2.0
    ringPath.stroke()
    
    screen.unlockFocus()
    return screen
}

// Screen 5: 4K 60FPS Ultra HD Export
func buildAppScreen5(orig: NSImage, cinematic: NSImage) -> NSImage {
    let screen = NSImage(size: NSSize(width: 460, height: 1024))
    screen.lockFocus()
    
    // 1. Draw original base
    orig.draw(in: NSRect(x: 0, y: 0, width: 460, height: 1024))
    
    // 2. Behind dialog: replace video with cinematic photo under dark overlay
    let cardRect = rectFromTop(x: 13, y: 112, width: 434, height: 340, totalHeight: 1024)
    let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 18, yRadius: 18)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.saveGState()
    cardPath.addClip()
    drawImageAspectFill(image: cinematic, in: cardRect)
    hexColor("#000000", alpha: 0.65).setFill()
    cardRect.fill()
    ctx.restoreGState()
    
    // 3. Highlight 4K resolution pill in pink!
    // In original, 1080p was at x=228, y=528, w=70, h=34. 4K is at x=418..445 (or 2K/4K).
    // Let's redraw the 4K pill with bright hot pink:
    // Resolution pills row: y: 528..562
    // 360p, 480p, 720p, 1080p, 1440p (2K), 4K
    // Let's draw 1080p normal dark pill, and 4K as active pink pill!
    
    // Reset 1080p to dark pill
    let pill1080 = rectFromTop(x: 228, y: 528, width: 70, height: 34, totalHeight: 1024)
    let p1080Path = NSBezierPath(roundedRect: pill1080, xRadius: 17, yRadius: 17)
    hexColor("#2D1D27").setFill()
    p1080Path.fill()
    let str1080 = NSAttributedString(string: "1080p", attributes: [.font: NSFont.systemFont(ofSize: 13, weight: .semibold), .foregroundColor: hexColor("#D0C4CE")])
    str1080.draw(at: NSPoint(x: pill1080.midX - str1080.size().width / 2, y: pill1080.midY - str1080.size().height / 2))
    
    // Draw 4K Ultra HD pill in vibrant hot pink!
    let pill4K = rectFromTop(x: 418, y: 528, width: 40, height: 34, totalHeight: 1024)
    let p4KPath = NSBezierPath(roundedRect: pill4K, xRadius: 17, yRadius: 17)
    hexColor("#FF2E63").setFill()
    p4KPath.fill()
    let str4K = NSAttributedString(string: "4K", attributes: [.font: NSFont.systemFont(ofSize: 13, weight: .bold), .foregroundColor: NSColor.white])
    str4K.draw(at: NSPoint(x: pill4K.midX - str4K.size().width / 2, y: pill4K.midY - str4K.size().height / 2))
    
    // 4. Highlight 60 FPS pill in pink!
    // FPS pills row: y: 624..658
    // 24, 25, 30 (was pink), 50, 60 (at x=265)
    
    // Reset 30 fps to dark pill
    let pill30 = rectFromTop(x: 144, y: 624, width: 44, height: 34, totalHeight: 1024)
    let p30Path = NSBezierPath(roundedRect: pill30, xRadius: 17, yRadius: 17)
    hexColor("#2D1D27").setFill()
    p30Path.fill()
    let str30 = NSAttributedString(string: "30", attributes: [.font: NSFont.systemFont(ofSize: 13, weight: .semibold), .foregroundColor: hexColor("#D0C4CE")])
    str30.draw(at: NSPoint(x: pill30.midX - str30.size().width / 2, y: pill30.midY - str30.size().height / 2))
    
    // Draw 60 fps in vibrant hot pink!
    let pill60 = rectFromTop(x: 265, y: 624, width: 44, height: 34, totalHeight: 1024)
    let p60Path = NSBezierPath(roundedRect: pill60, xRadius: 17, yRadius: 17)
    hexColor("#FF2E63").setFill()
    p60Path.fill()
    let str60 = NSAttributedString(string: "60", attributes: [.font: NSFont.systemFont(ofSize: 13, weight: .bold), .foregroundColor: NSColor.white])
    str60.draw(at: NSPoint(x: pill60.midX - str60.size().width / 2, y: pill60.midY - str60.size().height / 2))
    
    screen.unlockFocus()
    return screen
}

// -------------------------------------------------------------
// MAIN PROMOTIONAL SCREENSHOT BUILDER
// -------------------------------------------------------------
struct ScreenshotSpec {
    let index: Int
    let badge: String
    let title: String
    let subtitle: String
    let bgColors: [NSColor]
    let glowColor1: NSColor
    let glowCenter1: CGPoint
    let glowRadius1: CGFloat
    let glowColor2: NSColor
    let glowCenter2: CGPoint
    let glowRadius2: CGFloat
    let badge1: (icon: String, text: String, x: CGFloat, y: CGFloat, w: CGFloat)
    let badge2: (icon: String, text: String, x: CGFloat, y: CGFloat, w: CGFloat)
    let badge3: (icon: String, text: String, x: CGFloat, y: CGFloat, w: CGFloat)
}

let specs: [ScreenshotSpec] = [
    // 1: Pro Video Editor
    ScreenshotSpec(
        index: 1,
        badge: "✦ ALL-IN-ONE VIDEO MAKER",
        title: "PRO VIDEO EDITOR",
        subtitle: "Multi-Track Timeline • Music & Voiceover",
        bgColors: [hexColor("#080A12"), hexColor("#101322")],
        glowColor1: hexColor("#FF2E63", alpha: 0.18),
        glowCenter1: CGPoint(x: 880, y: 1900),
        glowRadius1: 650,
        glowColor2: hexColor("#4A00E0", alpha: 0.14),
        glowCenter2: CGPoint(x: 200, y: 1200),
        glowRadius2: 500,
        badge1: (icon: "🎵", text: "Add Music & Beats", x: 40, y: 720, w: 380),
        badge2: (icon: "✂️", text: "Precision Cut & Trim", x: 650, y: 1280, w: 390),
        badge3: (icon: "✨", text: "100% Free • No Watermark", x: 45, y: 1920, w: 440)
    ),
    // 2: Canvas & Aspect Ratio
    ScreenshotSpec(
        index: 2,
        badge: "✦ RATIO & CANVAS",
        title: "FIT FOR ANY PLATFORM",
        subtitle: "TikTok, Reels, Shorts & YouTube",
        bgColors: [hexColor("#070A18"), hexColor("#10182C")],
        glowColor1: hexColor("#00F2FE", alpha: 0.15),
        glowCenter1: CGPoint(x: 850, y: 1850),
        glowRadius1: 600,
        glowColor2: hexColor("#FF2E63", alpha: 0.15),
        glowCenter2: CGPoint(x: 200, y: 1300),
        glowRadius2: 500,
        badge1: (icon: "📱", text: "9:16 Reels & TikTok", x: 40, y: 720, w: 380),
        badge2: (icon: "🎬", text: "16:9 YouTube Cinema", x: 650, y: 1280, w: 390),
        badge3: (icon: "⬛", text: "1:1 Instagram Square", x: 45, y: 1920, w: 400)
    ),
    // 3: Smart Subtitles
    ScreenshotSpec(
        index: 3,
        badge: "✦ AUTO CAPTIONS",
        title: "SMART SUBTITLES",
        subtitle: "SRT Subtitle Sync & Animated Text",
        bgColors: [hexColor("#0C0716"), hexColor("#171026")],
        glowColor1: hexColor("#FF2E63", alpha: 0.18),
        glowCenter1: CGPoint(x: 880, y: 1900),
        glowRadius1: 650,
        glowColor2: hexColor("#7928CA", alpha: 0.16),
        glowCenter2: CGPoint(x: 180, y: 1250),
        glowRadius2: 500,
        badge1: (icon: "⚡", text: "One-Tap SRT Sync", x: 40, y: 720, w: 370),
        badge2: (icon: "💬", text: "Real-Time Video Text", x: 640, y: 1280, w: 400),
        badge3: (icon: "🎯", text: "Frame-Accurate Timing", x: 45, y: 1920, w: 420)
    ),
    // 4: Doodle & Handwriting
    ScreenshotSpec(
        index: 4,
        badge: "✦ CREATIVE DOODLE",
        title: "DRAW ON VIDEO",
        subtitle: "Glowing Brush Effects & Color Palette",
        bgColors: [hexColor("#0E0616"), hexColor("#1B0C24")],
        glowColor1: hexColor("#FF007F", alpha: 0.20),
        glowCenter1: CGPoint(x: 860, y: 1900),
        glowRadius1: 650,
        glowColor2: hexColor("#8A2BE2", alpha: 0.16),
        glowCenter2: CGPoint(x: 200, y: 1200),
        glowRadius2: 520,
        badge1: (icon: "✨", text: "Neon Glow Brush", x: 40, y: 720, w: 370),
        badge2: (icon: "🎨", text: "Vibrant Color Palette", x: 650, y: 1280, w: 390),
        badge3: (icon: "🖌️", text: "Frame-by-Frame Doodle", x: 45, y: 1920, w: 430)
    ),
    // 5: 4K 60FPS Ultra HD Export
    ScreenshotSpec(
        index: 5,
        badge: "✦ CINEMATIC EXPORT",
        title: "4K 60FPS ULTRA HD",
        subtitle: "Crystal Clear Quality • Fast Rendering",
        bgColors: [hexColor("#09090F"), hexColor("#14141E")],
        glowColor1: hexColor("#FF2E63", alpha: 0.18),
        glowCenter1: CGPoint(x: 880, y: 1900),
        glowRadius1: 650,
        glowColor2: hexColor("#FFAA00", alpha: 0.12),
        glowCenter2: CGPoint(x: 180, y: 1250),
        glowRadius2: 500,
        badge1: (icon: "💎", text: "4K Ultra HD (2160p)", x: 40, y: 720, w: 390),
        badge2: (icon: "⚡", text: "60 FPS Ultra Smooth", x: 640, y: 1280, w: 400),
        badge3: (icon: "🎵", text: "Extract Audio MP3", x: 45, y: 1920, w: 390)
    )
]

// Paths to assets
let uploadedBasePath = "/Users/naeem/.gemini/antigravity/brain/d986efc7-c9ed-4c15-8f32-12b200ba8330/.user_uploaded"
let sourcesPath = "/Users/naeem/Documents/Developer/Android/LibreCuts/screenshots_source"

let uploadedFiles = [
    "\(uploadedBasePath)/media_1794082841179_dee3d64f.jpg", // 1
    "\(uploadedBasePath)/media_1794082841180_484247f0.jpg", // 2
    "\(uploadedBasePath)/media_1794082841179_90cc04fd.jpg", // 3
    "\(uploadedBasePath)/media_1794082841180_9d02f41c.jpg", // 4
    "\(uploadedBasePath)/media_1794082841182_70bba7bf.jpg"  // 5
]

let photoFiles = [
    "\(sourcesPath)/vlogger.jpg",
    "\(sourcesPath)/fashion.jpg",
    "\(sourcesPath)/speaker.jpg",
    "\(sourcesPath)/dancer_portrait.jpg",
    "\(sourcesPath)/cinematic.jpg"
]

// Destinations
let fastlaneDir = "/Users/naeem/Documents/Developer/Android/LibreCuts/fastlane/metadata/android/en-US/images/phoneScreenshots"
let srcImagesDir = "/Users/naeem/Documents/Developer/Android/LibreCuts/src/images"

// Build and save each screenshot
for spec in specs {
    let idx = spec.index - 1
    guard let origImg = NSImage(contentsOfFile: uploadedFiles[idx]),
          let photoImg = NSImage(contentsOfFile: photoFiles[idx]) else {
        print("Missing asset for screen \(spec.index)")
        continue
    }
    
    // 1. Build enhanced app screen
    let appScreen: NSImage
    switch spec.index {
    case 1: appScreen = buildAppScreen1(orig: origImg, vlogger: photoImg)
    case 2: appScreen = buildAppScreen2(orig: origImg, fashion: photoImg)
    case 3: appScreen = buildAppScreen3(orig: origImg, speaker: photoImg)
    case 4: appScreen = buildAppScreen4(orig: origImg, dancer: photoImg)
    case 5: appScreen = buildAppScreen5(orig: origImg, cinematic: photoImg)
    default: fatalError()
    }
    
    // 2. Build full canvas promotional screenshot (1080 x 2400)
    let promoCanvas = NSImage(size: NSSize(width: canvasWidth, height: canvasHeight))
    promoCanvas.lockFocus()
    let ctx = NSGraphicsContext.current!.cgContext
    
    // Gradient Background
    drawLinearGradient(colors: spec.bgColors, start: CGPoint(x: 540, y: 2400), end: CGPoint(x: 540, y: 0), context: ctx)
    drawRadialGlow(center: spec.glowCenter1, radius: spec.glowRadius1, color: spec.glowColor1, context: ctx)
    drawRadialGlow(center: spec.glowCenter2, radius: spec.glowRadius2, color: spec.glowColor2, context: ctx)
    
    // Header
    drawHeader(badge: spec.badge, title: spec.title, subtitle: spec.subtitle, context: ctx)
    
    // Phone Mockup (840 x 1880)
    let phoneRect = rectFromTop(x: 120, y: 440, width: 840, height: 1880, totalHeight: canvasHeight)
    drawPhoneMockup(screenImage: appScreen, targetRect: phoneRect, context: ctx)
    
    // 3 Floating Badges
    drawFloatingBadge(icon: spec.badge1.icon, text: spec.badge1.text, x: spec.badge1.x, y: spec.badge1.y, width: spec.badge1.w, height: 78, context: ctx)
    drawFloatingBadge(icon: spec.badge2.icon, text: spec.badge2.text, x: spec.badge2.x, y: spec.badge2.y, width: spec.badge2.w, height: 78, context: ctx)
    drawFloatingBadge(icon: spec.badge3.icon, text: spec.badge3.text, x: spec.badge3.x, y: spec.badge3.y, width: spec.badge3.w, height: 78, context: ctx)
    
    promoCanvas.unlockFocus()
    
    // Export PNG
    let rep = NSBitmapImageRep(data: promoCanvas.tiffRepresentation!)!
    let pngData = rep.representation(using: .png, properties: [:])!
    
    // Save to fastlane
    let fastlanePath = "\(fastlaneDir)/\(spec.index).png"
    try! pngData.write(to: URL(fileURLWithPath: fastlanePath))
    
    // Save to src/images
    let srcPath = "\(srcImagesDir)/sc_\(spec.index).png"
    try! pngData.write(to: URL(fileURLWithPath: srcPath))
    
    print("✅ Created Screenshot \(spec.index): \(spec.title) -> \(fastlanePath)")
}

// -------------------------------------------------------------
// FEATURE GRAPHIC GENERATOR (1024 x 500 px for Google Play Store)
// -------------------------------------------------------------
let fgWidth: CGFloat = 1024
let fgHeight: CGFloat = 500
let fgCanvas = NSImage(size: NSSize(width: fgWidth, height: fgHeight))
fgCanvas.lockFocus()
let fgCtx = NSGraphicsContext.current!.cgContext

// Background
drawLinearGradient(colors: [hexColor("#080911"), hexColor("#121526")], start: CGPoint(x: 512, y: 500), end: CGPoint(x: 512, y: 0), context: fgCtx)
drawRadialGlow(center: CGPoint(x: 820, y: 250), radius: 350, color: hexColor("#FF2E63", alpha: 0.28), context: fgCtx)
drawRadialGlow(center: CGPoint(x: 200, y: 150), radius: 300, color: hexColor("#4A00E0", alpha: 0.18), context: fgCtx)

// Left side: App Branding
// App Icon / Logo
if let iconImg = NSImage(contentsOfFile: "/Users/naeem/Documents/Developer/Android/LibreCuts/fastlane/metadata/android/en-US/images/icon.png") {
    let iconRect = NSRect(x: 70, y: 310, width: 84, height: 84)
    let iconPath = NSBezierPath(roundedRect: iconRect, xRadius: 20, yRadius: 20)
    fgCtx.saveGState()
    fgCtx.setShadow(offset: CGSize(width: 0, height: -8), blur: 20, color: hexColor("#FF2E63", alpha: 0.4).cgColor)
    iconPath.addClip()
    iconImg.draw(in: iconRect)
    fgCtx.restoreGState()
}

// App Name
let appNameFont = NSFont.systemFont(ofSize: 52, weight: .heavy)
let appNameStr = NSAttributedString(string: "FlexCut", attributes: [.font: appNameFont, .foregroundColor: NSColor.white])
appNameStr.draw(at: NSPoint(x: 175, y: 335))

let tagFont = NSFont.systemFont(ofSize: 22, weight: .bold)
let tagStr = NSAttributedString(string: "PRO VIDEO EDITOR & MAKER", attributes: [.font: tagFont, .foregroundColor: hexColor("#FF2E63")])
tagStr.draw(at: NSPoint(x: 178, y: 305))

// Bullet points
let bullets = [
    "✦  Multi-Track Timeline & Audio Sync",
    "✦  Aspect Ratios for Reels, TikTok & YouTube",
    "✦  Auto Captions & Creative Doodle",
    "✦  Ultra HD 4K 60FPS • No Watermark"
]
let bFont = NSFont.systemFont(ofSize: 18, weight: .medium)
for (i, b) in bullets.enumerated() {
    let bStr = NSAttributedString(string: b, attributes: [.font: bFont, .foregroundColor: hexColor("#CBD5E1")])
    bStr.draw(at: NSPoint(x: 75, y: 220 - CGFloat(i) * 38))
}

// Right side: Angled Smartphone Preview
if let screen1Img = NSImage(contentsOfFile: "\(fastlaneDir)/1.png") {
    let phoneW: CGFloat = 320
    let phoneH: CGFloat = 711
    let pRect = NSRect(x: 650, y: -130, width: phoneW, height: phoneH)
    
    fgCtx.saveGState()
    fgCtx.setShadow(offset: CGSize(width: -15, height: 10), blur: 30, color: NSColor.black.withAlphaComponent(0.75).cgColor)
    let pPath = NSBezierPath(roundedRect: pRect, xRadius: 32, yRadius: 32)
    pPath.addClip()
    screen1Img.draw(in: pRect)
    fgCtx.restoreGState()
    
    // Border
    hexColor("#353748").setStroke()
    pPath.lineWidth = 3.0
    pPath.stroke()
}

fgCanvas.unlockFocus()

let fgRep = NSBitmapImageRep(data: fgCanvas.tiffRepresentation!)!
let fgPngData = fgRep.representation(using: .png, properties: [:])!
try! fgPngData.write(to: URL(fileURLWithPath: "\(fastlaneDir)/../featureGraphic.png"))
try! fgPngData.write(to: URL(fileURLWithPath: "\(srcImagesDir)/featureGraphic.png"))
print("✅ Created Feature Graphic (1024 x 500) -> fastlane & src/images!")
