import SwiftUI

// MARK: - Color Wheel Renderer

enum ColorWheelRenderer {
    private static let cache = NSCache<NSNumber, UIImage>()

    static func generateColorWheel(size: CGFloat) -> UIImage? {
        let key = NSNumber(value: Int(size))
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let image = generateColorWheelUncached(size: size) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    private static func generateColorWheelUncached(size: CGFloat) -> UIImage? {
        let width = Int(size)
        let height = Int(size)
        let centerX = width / 2
        let centerY = height / 2
        let radius = Double(width) / 2.0

        var pixels = [UInt32](repeating: 0, count: width * height)

        for y in 0..<height {
            for x in 0..<width {
                let dx = Double(x - centerX)
                let dy = Double(y - centerY)
                let distance = sqrt(dx * dx + dy * dy)

                guard distance <= radius else { continue }

                let angle = atan2(dy, dx)
                let hue = ((angle * 180.0 / .pi) + 90.0 + 360.0)
                    .truncatingRemainder(dividingBy: 360.0)
                let distanceRatio = distance / radius
                let saturation = distanceRatio
                let brightness = 1.0 - (distanceRatio * 0.45)

                let uiColor = UIColor(
                    hue: CGFloat(hue / 360.0),
                    saturation: CGFloat(saturation),
                    brightness: CGFloat(brightness),
                    alpha: 1.0
                )

                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil)

                let r = UInt32(red * 255)
                let g = UInt32(green * 255)
                let b = UInt32(blue * 255)

                pixels[y * width + x] = (255 << 24) | (r << 16) | (g << 8) | b
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }

        guard let cgImage = context.makeImage() else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Color Wheel View

struct ColorWheelView: View {
    @Binding var selectedColor: Color
    let onColorChanged: (() -> Void)?

    @State private var wheelImage: UIImage?
    @State private var pickerPosition: CGPoint = .zero

    private let wheelDisplaySize: CGFloat = 170

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = wheelImage {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: wheelDisplaySize, height: wheelDisplaySize)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 4)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleDrag(at: value.location)
                                }
                        )
                }

                Circle()
                    .fill(selectedColor)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 2)
                    .position(pickerPosition)
            }
            .onAppear {
                pickerPosition = positionForColor(
                    selectedColor,
                    in: CGSize(width: wheelDisplaySize, height: wheelDisplaySize)
                )
                if wheelImage == nil {
                    DispatchQueue.global(qos: .userInitiated).async {
                        let image = ColorWheelRenderer.generateColorWheel(size: 480)
                        DispatchQueue.main.async {
                            wheelImage = image
                        }
                    }
                }
            }
            .onChange(of: selectedColor) { newColor in
                withAnimation(.easeOut(duration: 0.08)) {
                    pickerPosition = positionForColor(
                        newColor,
                        in: CGSize(width: wheelDisplaySize, height: wheelDisplaySize)
                    )
                }
            }
        }
        .frame(width: wheelDisplaySize, height: wheelDisplaySize)
    }

    private func handleDrag(at location: CGPoint) {
        let center = CGPoint(x: wheelDisplaySize / 2, y: wheelDisplaySize / 2)
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        let maxDistance = wheelDisplaySize / 2

        guard distance <= maxDistance else { return }

        let angle = atan2(dy, dx)
        let hue = ((angle * 180 / .pi) + 90 + 360)
            .truncatingRemainder(dividingBy: 360)
        let distanceRatio = distance / maxDistance
        let saturation = distanceRatio
        let brightness = 1.0 - (distanceRatio * 0.45)

        selectedColor = Color(
            hue: hue / 360,
            saturation: saturation,
            brightness: brightness
        )
        pickerPosition = location
        HapticManager.selection()
        onColorChanged?()
    }

    private func positionForColor(_ color: Color, in size: CGSize) -> CGPoint {
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)

        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let maxDistance = size.width / 2
        let distance = saturation * maxDistance
        let angle = (hue * 360 - 90) * .pi / 180

        return CGPoint(
            x: center.x + distance * cos(angle),
            y: center.y + distance * sin(angle)
        )
    }
}

// MARK: - Preview

#if DEBUG
struct ColorWheelView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(hex: "#1a1a1a").ignoresSafeArea()
            ColorWheelView(
                selectedColor: .constant(.pink),
                onColorChanged: nil
            )
        }
    }
}
#endif
