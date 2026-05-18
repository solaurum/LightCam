import SwiftUI

// MARK: - Color Wheel

struct ColorWheel: View {
    @Binding var color: Color
    let size: CGFloat

    @State private var wheelImage: UIImage?
    @State private var pickerPoint: CGPoint = .zero

    var body: some View {
        ZStack {
            if let img = wheelImage {
                Image(uiImage: img)
                    .resizable()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle().fill(.gray.opacity(0.2))
            }

            // Color picker crosshair
            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 28, height: 28)
                .shadow(color: .black.opacity(0.5), radius: 4)
                .position(pickerPoint == .zero ? CGPoint(x: size / 2, y: size / 2) : pickerPoint)
        }
        .frame(width: size, height: size)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    pickColor(at: value.location)
                }
        )
        .onAppear {
            wheelImage = renderWheel(size: size * 3) // 3x for retina
            updatePickerFromColor()
        }
        .onChange(of: color) { _ in
            updatePickerFromColor()
        }
        .onChange(of: size) { newSize in
            wheelImage = renderWheel(size: newSize * 3)
        }
    }

    private func pickColor(at location: CGPoint) {
        let cx = size / 2, cy = size / 2
        let dx = location.x - cx, dy = location.y - cy
        var dist = sqrt(dx * dx + dy * dy)
        let r = size / 2
        dist = min(dist, r)

        if dist > 0 {
            let angle = atan2(dy, dx)
            let hue = ((angle * 180 / .pi + 90) + 360).truncatingRemainder(dividingBy: 360)
            let sat = dist / r
            let rgb = hslToRgb(h: hue, s: sat, l: 0.55)
            color = Color(red: Double(rgb.r) / 255, green: Double(rgb.g) / 255, blue: Double(rgb.b) / 255)

            let px = cx + cos(angle) * dist
            let py = cy + sin(angle) * dist
            pickerPoint = CGPoint(x: px, y: py)
        }
    }

    private func updatePickerFromColor() {
        let uiColor = UIColor(color)
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)

        let rad = CGFloat(sat) * size / 2
        let angle = Double(hue) * 2 * .pi - .pi / 2
        let cx = size / 2, cy = size / 2
        pickerPoint = CGPoint(x: cx + cos(angle) * rad, y: cy + sin(angle) * rad)
    }

    private func renderWheel(size: CGFloat) -> UIImage {
        let step: CGFloat = 3
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { ctx in
            let r = size / 2, cx = size / 2, cy = size / 2
            let intSize = Int(size)
            for y in stride(from: 0, to: intSize, by: Int(step)) {
                let dy = CGFloat(y) - cy
                for x in stride(from: 0, to: intSize, by: Int(step)) {
                    let dx = CGFloat(x) - cx
                    let dist = sqrt(dx * dx + dy * dy)
                    guard dist <= r else { continue }
                    let angle = atan2(dy, dx)
                    let hue = ((angle * 180 / .pi + 90) + 360).truncatingRemainder(dividingBy: 360)
                    let sat = dist / r
                    let color = hslToRgb(h: hue, s: sat, l: 0.55)
                    let fill = UIColor(red: CGFloat(color.r) / 255, green: CGFloat(color.g) / 255, blue: CGFloat(color.b) / 255, alpha: 1)
                    fill.setFill()
                    ctx.fill(CGRect(x: CGFloat(x), y: CGFloat(y), width: step, height: step))
                }
            }
        }
    }

    private func hslToRgb(h: CGFloat, s: CGFloat, l: CGFloat) -> (r: UInt8, g: UInt8, b: UInt8) {
        let c = (1 - abs(2 * l - 1)) * s
        let x = c * (1 - abs((h / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = l - c / 2
        let r1, g1, b1: CGFloat
        switch h {
        case 0..<60:  r1 = c; g1 = x; b1 = 0
        case 60..<120: r1 = x; g1 = c; b1 = 0
        case 120..<180: r1 = 0; g1 = c; b1 = x
        case 180..<240: r1 = 0; g1 = x; b1 = c
        case 240..<300: r1 = x; g1 = 0; b1 = c
        default:       r1 = c; g1 = 0; b1 = x
        }
        return (UInt8((r1 + m) * 255), UInt8((g1 + m) * 255), UInt8((b1 + m) * 255))
    }
}

// MARK: - Color Preset Editor

struct ColorPresetEditor: View {
    @EnvironmentObject var loc: LocalizationManager
    @Binding var customPresets: [LightPreset]
    @Binding var isPresented: Bool
    let editingPreset: LightPreset?

    @State private var selectedMode: PresetMode = .solid
    @State private var firstColor: Color = .white
    @State private var secondColor: Color = .gray
    @State private var activeColor: Int = 0

    init(customPresets: Binding<[LightPreset]>, isPresented: Binding<Bool>,
         editingPreset: LightPreset? = nil) {
        self._customPresets = customPresets
        self._isPresented = isPresented
        self.editingPreset = editingPreset
        if let p = editingPreset {
            self._selectedMode = State(initialValue: p.mode)
            self._firstColor = State(initialValue: p.color)
            self._secondColor = State(initialValue: p.secondColor)
        }
    }

    private var isEditing: Bool { editingPreset != nil }
    private var needsSecondColor: Bool { selectedMode != .solid }

    var body: some View {
        GeometryReader { geo in
            let wheelSize = min(geo.size.width * 0.8, geo.size.height * 0.42)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(isEditing ? loc.string("edit_preset") : loc.string("new_preset"))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                // Full-page color wheel
                ColorWheel(color: activeColor == 0 ? $firstColor : $secondColor, size: wheelSize)
                    .padding(.top, 8)

                // Dual color selector
                if needsSecondColor {
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Circle().fill(firstColor).frame(width: 14, height: 14)
                            Text(loc.string("primary")).font(.system(size: 11)).foregroundColor(activeColor == 0 ? .white : .secondary)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(activeColor == 0 ? Color.white.opacity(0.1) : Color.clear)
                        .clipShape(Capsule())
                        .onTapGesture { activeColor = 0 }

                        HStack(spacing: 6) {
                            Circle().fill(secondColor).frame(width: 14, height: 14)
                            Text(loc.string("secondary")).font(.system(size: 11)).foregroundColor(activeColor == 1 ? .white : .secondary)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(activeColor == 1 ? Color.white.opacity(0.1) : Color.clear)
                        .clipShape(Capsule())
                        .onTapGesture { activeColor = 1 }
                    }
                    .padding(.top, 10)
                }

                // Mode selector
                HStack(spacing: 6) {
                    modeTab(.solid, "square.fill", loc.string("mode_solid"))
                    modeTab(.gradientTopBottom, "square.split.2x1.fill", loc.string("mode_gradient"))
                    modeTab(.dualLeftRight, "rectangle.split.2x1.fill", loc.string("mode_dual"))
                }
                .padding(.top, 12)

                Spacer(minLength: 8)

                // Save
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    performSave()
                } label: {
                    Text(isEditing ? loc.string("update") : loc.string("save_preset"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(firstColor.opacity(0.45))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(white: 0.12))
        .preferredColorScheme(.dark)
    }

    private func modeTab(_ mode: PresetMode, _ icon: String, _ label: String) -> some View {
        let active = selectedMode == mode
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedMode = mode }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 12))
                Text(label).font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(active ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(active ? firstColor.opacity(0.35) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(active ? firstColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
    }

    // MARK: - Save

    private func performSave() {
        let firstUIColor = UIColor(firstColor)
        var secondUIColor: UIColor?
        if needsSecondColor { secondUIColor = UIColor(secondColor) }

        let name: String
        if isEditing, let existing = editingPreset {
            name = existing.name
            let updated = LightPreset(
                id: existing.id, name: name, mode: selectedMode,
                first: firstUIColor, second: secondUIColor,
                defaultScreenBrightness: 0.88
            )
            if let idx = customPresets.firstIndex(where: { $0.id == existing.id }) {
                customPresets[idx] = updated
            }
        } else {
            let count = customPresets.count + 1
            name = "Custom \(count)"
            let id = UserDefaults.standard.allocateCustomPresetId()
            let preset = LightPreset(
                id: id, name: name, mode: selectedMode,
                first: firstUIColor, second: secondUIColor,
                defaultScreenBrightness: 0.88
            )
            customPresets.append(preset)
        }
        UserDefaults.standard.saveCustomPresets(customPresets)
        isPresented = false
    }
}
