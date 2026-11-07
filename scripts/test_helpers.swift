import Cocoa

// Helper function to create NSImage from file
func loadImage(_ path: String) -> NSImage? {
    return NSImage(contentsOfFile: path)
}

// Helper to draw rounded image
func drawImageCropped(image: NSImage, in rect: NSRect, cornerRadius: CGFloat, context: CGContext) {
    context.saveGState()
    let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    context.addPath(path)
    context.clip()
    
    // Scale aspect fill
    let imgSize = image.size
    let scale = max(rect.width / imgSize.width, rect.height / imgSize.height)
    let drawWidth = imgSize.width * scale
    let drawHeight = imgSize.height * scale
    let drawX = rect.midX - drawWidth / 2
    let drawY = rect.midY - drawHeight / 2
    
    if let cgImg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        context.draw(cgImg, in: CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight))
    }
    context.restoreGState()
}

print("Loaded helper methods")
