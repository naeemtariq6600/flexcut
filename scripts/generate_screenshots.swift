import Cocoa

let canvasWidth: CGFloat = 1080
let canvasHeight: CGFloat = 2400

func rectFromTop(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, totalHeight: CGFloat = canvasHeight) -> NSRect {
    return NSRect(x: x, y: totalHeight - y - height, width: width, height: height)
}

func hexColor(_ hex: String, alpha: CGFloat = 1.0) -> NSColor {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
    var rgb: UInt64 = 0
    Scanner(string: hexSanitized).scanHexInt64(&rgb)
    let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
    let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
    let b = CGFloat(rgb & 0x0000FF) / 255.0
    return NSColor(red: r, green: g, blue: b, alpha: alpha)
}

// Draw linear gradient
func drawLinearGradient(colors: [NSColor], start: CGPoint, end: CGPoint, context: CGContext) {
    let cgColors = colors.map { $0.cgColor } as CFArray
    let space = CGColorSpaceCreateDeviceRGB()
    if let gradient = CGGradient(colorsSpace: space, colors: cgColors, locations: nil) {
        context.drawLinearGradient(gradient, start: start, end: end, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }
}

// Draw radial glow
func drawRadialGlow(center: CGPoint, radius: CGFloat, color: NSColor, context: CGContext) {
    context.saveGState()
    let colors = [color.cgColor, color.withAlphaComponent(0.0).cgColor] as CFArray
    let space = CGColorSpaceCreateDeviceRGB()
    if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0.0, 1.0]) {
        context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [.drawsAfterEndLocation])
    }
    context.restoreGState()
}

// Draw Category Badge
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
    
    hexColor("#FF2E63", alpha: 0.40).setStroke()
    path.lineWidth = 1.5
    path.stroke()
    
    let textPoint = NSPoint(x: badgeRect.midX - textWidth / 2, y: badgeRect.midY - attrStr.size().height / 2 + 1)
    attrStr.draw(at: textPoint)
}

// Draw Header block (Badge, Title, Subtitle)
func drawHeader(badge: String, title: String, subtitle: String, context: CGContext) {
    // 1. Badge centered at top
    let fontBadge = NSFont.systemFont(ofSize: 22, weight: .bold)
    let attrBadge = NSAttributedString(string: badge, attributes: [.font: fontBadge, .foregroundColor: hexColor("#FF2E63")])
    let bWidth = attrBadge.size().width + 44
    let bX = (canvasWidth - bWidth) / 2
    drawCategoryBadge(text: badge, x: bX, y: 130, height: 52)
    
    // 2. Main Title
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
    
    // 3. Subtitle
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

// Draw Floating Glass Badge with soft shadow
func drawFloatingBadge(icon: String, text: String, x: CGFloat, y: CGFloat, width: CGFloat = 360, height: CGFloat = 76, context: CGContext) {
    let badgeRect = rectFromTop(x: x, y: y, width: width, height: height)
    
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -14), blur: 28, color: NSColor.black.withAlphaComponent(0.70).cgColor)
    
    let path = NSBezierPath(roundedRect: badgeRect, xRadius: height / 2, yRadius: height / 2)
    hexColor("#151824", alpha: 0.94).setFill()
    path.fill()
    context.restoreGState()
    
    // Border
    hexColor("#FFFFFF", alpha: 0.18).setStroke()
    path.lineWidth = 1.5
    path.stroke()
    
    // Inner subtle glow border
    let innerPath = NSBezierPath(roundedRect: badgeRect.insetBy(dx: 1.5, dy: 1.5), xRadius: (height - 3) / 2, yRadius: (height - 3) / 2)
    hexColor("#FF2E63", alpha: 0.22).setStroke()
    innerPath.lineWidth = 1.0
    innerPath.stroke()
    
    // Icon & Text
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

// Draw Phone Bezel & Screen
func drawPhoneMockup(screenImage: NSImage, targetRect: NSRect, context: CGContext) {
    let chassisRect = targetRect
    let cornerRadius: CGFloat = 54
    let bezelThickness: CGFloat = 14
    let screenRadius: CGFloat = cornerRadius - bezelThickness
    
    // 1. Phone Drop Shadow
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -30), blur: 50, color: NSColor.black.withAlphaComponent(0.85).cgColor)
    let chassisPath = NSBezierPath(roundedRect: chassisRect, xRadius: cornerRadius, yRadius: cornerRadius)
    hexColor("#181924").setFill()
    chassisPath.fill()
    context.restoreGState()
    
    // 2. Chassis rim & metallic edge
    hexColor("#353748").setStroke()
    chassisPath.lineWidth = 2.0
    chassisPath.stroke()
    
    // Subtle outer light rim
    let rimPath = NSBezierPath(roundedRect: chassisRect.insetBy(dx: 1, dy: 1), xRadius: cornerRadius - 1, yRadius: cornerRadius - 1)
    hexColor("#505470", alpha: 0.35).setStroke()
    rimPath.lineWidth = 1.0
    rimPath.stroke()
    
    // 3. Screen Area
    let screenRect = chassisRect.insetBy(dx: bezelThickness, dy: bezelThickness)
    let screenPath = NSBezierPath(roundedRect: screenRect, xRadius: screenRadius, yRadius: screenRadius)
    
    context.saveGState()
    screenPath.addClip()
    
    // Draw screenImage aspect-fill into screenRect
    screenImage.draw(in: screenRect)
    
    // 4. Dynamic Island / Punch Hole at top of screen
    let holeWidth: CGFloat = 84
    let holeHeight: CGFloat = 24
    let holeRect = NSRect(x: screenRect.midX - holeWidth / 2, y: screenRect.maxY - 34, width: holeWidth, height: holeHeight)
    let holePath = NSBezierPath(roundedRect: holeRect, xRadius: holeHeight / 2, yRadius: holeHeight / 2)
    hexColor("#08080C").setFill()
    holePath.fill()
    
    // Lens reflection
    let lensRect = NSRect(x: holeRect.minX + 16, y: holeRect.midY - 4, width: 8, height: 8)
    let lensPath = NSBezierPath(ovalIn: lensRect)
    hexColor("#1B2A40").setFill()
    lensPath.fill()
    
    // Subtle screen glass diagonal reflection
    let sheenPath = NSBezierPath()
    sheenPath.move(to: NSPoint(x: screenRect.minX, y: screenRect.maxY))
    sheenPath.line(to: NSPoint(x: screenRect.minX + 260, y: screenRect.maxY))
    sheenPath.line(to: NSPoint(x: screenRect.minX, y: screenRect.maxY - 500))
    sheenPath.close()
    hexColor("#FFFFFF", alpha: 0.035).setFill()
    sheenPath.fill()
    
    context.restoreGState()
    
    // Screen inner bezel shadow
    hexColor("#000000", alpha: 0.4).setStroke()
    screenPath.lineWidth = 1.5
    screenPath.stroke()
}

print("Base layout system ready")
