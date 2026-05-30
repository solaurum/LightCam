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
    @State private var splitDirection: SplitDirection = .horizontal

    init(customPresets: Binding<[LightPreset]>, isPresented: Binding<Bool>,
         editingPreset: LightPreset? = nil) {
        self._customPresets = customPresets
        self._isPresented = isPresented
        self.editingPreset = editingPreset
        if let p = editingPreset {
            self._selectedMode = State(initialValue: p.mode)
            self._firstColor = State(initialValue: p.color)
            self._secondColor = State(initialValue: p.secondColor)
            self._splitDirection = State(initialValue: p.splitDirection)
        }
    }

    private var isEditing: Bool { editingPreset != nil }
    private var needsSecondColor: Bool { selectedMode != .solid }

    var body: some View {
        GeometryReader { geo in
            let wheelSize = min(geo.size.width * 0.66, geo.size.height * 0.38)

            ZStack {
                // Background — matching presets picker
                LinearGradient(
                    colors: [Color(red: 0.06, green: 0.04, blue: 0.12),
                             Color(red: 0.03, green: 0.02, blue: 0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Subtle sparkles
                AnimeSparkleView(count: 5, color: Color(red: 0.706, green: 0.573, blue: 0.878))
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text(isEditing ? loc.string("edit_preset") : loc.string("new_preset"))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isPresented = false
                            }
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
                    .padding(.top, 16)
                    .padding(.bottom, 10)

                    ScrollView {
                        VStack(spacing: 14) {
                            // Color wheel — centered
                            ColorWheel(color: activeColor == 0 ? $firstColor : $secondColor, size: wheelSize)

                            // Dual color selector
                            if needsSecondColor {
                                HStack(spacing: 14) {
                                    colorChip(label: loc.string("primary"), color: firstColor, isActive: activeColor == 0)
                                        .onTapGesture { activeColor = 0 }
                                    colorChip(label: loc.string("secondary"), color: secondColor, isActive: activeColor == 1)
                                        .onTapGesture { activeColor = 1 }
                                }
                            }

                            // Mode selector + direction — card style
                            VStack(spacing: 10) {
                                HStack(spacing: 6) {
                                    modeTab(.solid, "square.fill", loc.string("mode_solid"))
                                    modeTab(.gradientTopBottom, "square.split.2x1.fill", loc.string("mode_gradient"))
                                    modeTab(.dualLeftRight, "rectangle.split.2x1.fill", loc.string("mode_dual"))
                                }

                                if selectedMode != .solid {
                                    HStack(spacing: 8) {
                                        ForEach(SplitDirection.allCases, id: \.self) { dir in
                                            splitDirectionChip(dir)
                                        }
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }

                    // Save button — centered, narrow
                    Button {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        performSave()
                    } label: {
                        Text(isEditing ? loc.string("update") : loc.string("save_preset"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 42)
                            .padding(.vertical, 12)
                            .background(firstColor.opacity(0.45))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.bottom, max(geo.safeAreaInsets.bottom, 12))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Color Chip

    private func colorChip(label: String, color: Color, isActive: Bool) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 14, height: 14)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isActive ? .white : .white.opacity(0.45))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(isActive ? Color.white.opacity(0.1) : Color.white.opacity(0.03))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isActive ? firstColor.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
        )
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

    private func splitDirectionChip(_ dir: SplitDirection) -> some View {
        let active = splitDirection == dir
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { splitDirection = dir }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 4) {
                splitDirectionIcon(dir)
                    .frame(width: 16, height: 16)
                Text(splitDirectionLabel(dir))
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundColor(active ? .white : .white.opacity(0.5))
            .background(
                active
                    ? RoundedRectangle(cornerRadius: 10).fill(firstColor.opacity(0.35))
                    : RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(active ? firstColor.opacity(0.5) : Color.white.opacity(0.1), lineWidth: active ? 1.5 : 1)
            )
        }
    }

    @ViewBuilder
    private func splitDirectionIcon(_ dir: SplitDirection) -> some View {
        switch dir {
        case .horizontal:
            HStack(spacing: 0) {
                Rectangle().fill(firstColor)
                Rectangle().fill(secondColor)
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
        case .vertical:
            VStack(spacing: 0) {
                Rectangle().fill(firstColor)
                Rectangle().fill(secondColor)
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
        case .diagonalLeft:
            Rectangle()
                .fill(LinearGradient(colors: [firstColor, secondColor], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(RoundedRectangle(cornerRadius: 2))
        case .diagonalRight:
            Rectangle()
                .fill(LinearGradient(colors: [firstColor, secondColor], startPoint: .topTrailing, endPoint: .bottomLeading))
                .clipShape(RoundedRectangle(cornerRadius: 2))
        }
    }

    private func splitDirectionLabel(_ dir: SplitDirection) -> String {
        switch dir {
        case .horizontal:    return loc.string("split_horizontal")
        case .vertical:      return loc.string("split_vertical")
        case .diagonalLeft:  return loc.string("split_diagonal_left")
        case .diagonalRight: return loc.string("split_diagonal_right")
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
                defaultScreenBrightness: 0.88,
                splitDirection: splitDirection
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
                defaultScreenBrightness: 0.88,
                splitDirection: splitDirection
            )
            customPresets.append(preset)
        }
        UserDefaults.standard.saveCustomPresets(customPresets)
        isPresented = false
    }
}
