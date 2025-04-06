import SwiftUI

struct IconGenerator {
    static func generateIcon(size: CGFloat) -> UIImage {
        let config = UIImage.SymbolConfiguration(pointSize: size * 0.6, weight: .bold)
        let image = UIImage(systemName: "basket.fill", withConfiguration: config)!
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let finalImage = renderer.image { context in
            // Draw background
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))
            
            // Draw icon centered
            let iconRect = CGRect(
                x: (size - image.size.width) / 2,
                y: (size - image.size.height) / 2,
                width: image.size.width,
                height: image.size.height
            )
            image.draw(in: iconRect)
        }
        
        return finalImage
    }
    
    static func generateAllIcons() {
        let sizes = [
            (40, "Icon-40"),    // 20pt @2x
            (60, "Icon-60"),    // 20pt @3x
            (58, "Icon-58"),    // 29pt @2x
            (87, "Icon-87"),    // 29pt @3x
            (80, "Icon-80"),    // 40pt @2x
            (120, "Icon-120"),  // 40pt @3x, 60pt @2x
            (180, "Icon-180"),  // 60pt @3x
            (1024, "Icon-1024") // App Store
        ]
        
        for (size, name) in sizes {
            let image = generateIcon(size: CGFloat(size))
            if let data = image.pngData() {
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("\(name).png")
                try? data.write(to: url)
                print("Generated \(name).png")
            }
        }
    }
} 