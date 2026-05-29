import SwiftUI

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var loc: LocalizationManager
    @ObservedObject var cam: CameraManager

    @State private var currentPresetId = 1
    @State private var isMirrored = true
    @State private var screenBrightness: Double = 0.88
    @State private var capturedImage: UIImage?
    @State private var showingPreview = false
    @State private var showingPresets = false
    @State private var showingPermissionAlert = false
    @State private var customPresets: [LightPreset] = []
    @State private var showingColorEditor = false
    @State private var editingPreset: LightPreset?
    @State private var showingLanguagePicker = false
    @State private var deleteMode = false
    private let viewfinderWidth: CGFloat = 280
    private let viewfinderHeight: CGFloat = 280 * 4 / 3

    private let presets: [LightPreset] = [
        LightPreset(id: 0, name: "Studio White",  red: 1.0,  green: 1.0,  blue: 1.0,  temp: 6500, defaultScreenBrightness: 0.95),
        LightPreset(id: 1, name: "Golden Hour",   red: 1.0,  green: 0.55, blue: 0.20, temp: 3200, defaultScreenBrightness: 0.88),
        LightPreset(id: 2, name: "Fireside",      red: 1.0,  green: 0.40, blue: 0.10, temp: 2000, defaultScreenBrightness: 0.75),
        LightPreset(id: 3, name: "Morning Mist",  red: 0.68, green: 0.78, blue: 0.90, temp: 7500, defaultScreenBrightness: 0.85, defaultColorBrightness: 0.3),
        LightPreset(id: 4, name: "Honey Glow",    red: 1.0,  green: 0.82, blue: 0.45, temp: 4000, defaultScreenBrightness: 0.88),
        LightPreset(id: 5, name: "Rose Blush",    red: 1.0,  green: 0.50, blue: 0.60, temp: 3500, defaultScreenBrightness: 0.82, defaultColorBrightness: 0.4),
        LightPreset(id: 6, name: "Twilight Haze", red: 0.78, green: 0.65, blue: 1.0, temp: 5000, defaultScreenBrightness: 0.85, defaultColorBrightness: 0.35,
                    mode: .gradientTopBottom, secondRed: 0.91, secondGreen: 0.84, secondBlue: 0.98),
        LightPreset(id: 7, name: "Blue Hour",     red: 1.0, green: 0.55, blue: 0.26, temp: 3800, defaultScreenBrightness: 0.88,
                    mode: .dualLeftRight, secondRed: 0.42, secondGreen: 0.30, secondBlue: 0.72),
    ]

    private var allPresets: [LightPreset] { presets + customPresets }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fill light background
                fillLightBackground
                    .animation(.easeInOut(duration: 0.35), value: currentPresetId)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 50)
                            .onEnded { value in
                                let horizontal = abs(value.translation.width)
                                let vertical = abs(value.translation.height)
                                guard horizontal > vertical else { return }

                                let all = allPresets
                                guard let currentIdx = all.firstIndex(where: { $0.id == currentPresetId }),
                                      all.count > 1 else { return }

                                if value.translation.width < 0, currentIdx < all.count - 1 {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        currentPresetId = all[currentIdx + 1].id
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } else if value.translation.width > 0, currentIdx > 0 {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        currentPresetId = all[currentIdx - 1].id
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                    )

                // Color brightness overlay
                currentPreset.color
                    .opacity(currentPreset.defaultColorBrightness * 0.35)

                VStack(spacing: 0) {
                    Spacer()
                    viewfinderArea
                    Spacer()
                    bottomControls
                }
                .padding(.bottom, geometry.safeAreaInsets.bottom + 8)

                // Photo preview
                if showingPreview, let img = capturedImage {
                    photoPreview(img)
                }

                // Language picker overlay
                if showingLanguagePicker {
                    languagePickerOverlay
                }
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
        .onAppear {
            customPresets = UserDefaults.standard.loadCustomPresets()
            screenBrightness = currentPreset.defaultScreenBrightness
            UIScreen.main.brightness = screenBrightness
        }
        .onDisappear {}
        .onChange(of: currentPresetId) { _ in
            screenBrightness = currentPreset.defaultScreenBrightness
            UIScreen.main.brightness = screenBrightness
        }
        .fullScreenCover(isPresented: $showingPresets) { presetPicker }
        .sheet(isPresented: $showingColorEditor) {
            ColorPresetEditor(customPresets: $customPresets, isPresented: $showingColorEditor,
                              editingPreset: editingPreset)
                .environmentObject(loc)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
        .alert(loc.string("camera_permission_denied"), isPresented: $showingPermissionAlert) {
            Button(loc.string("open_settings"), action: openSettings)
            Button(loc.string("cancel"), role: .cancel) {}
        } message: {
            Text(loc.string("camera_permission_message"))
        }
        .onChange(of: cam.permissionDenied) { denied in
            if denied { showingPermissionAlert = true }
        }
    }

    // MARK: - Language Button

    private var languageButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showingLanguagePicker.toggle()
            }
        } label: {
            Text(loc.currentLanguage.shortName)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(contrastColor.opacity(0.7))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
        }
    }

    // MARK: - Language Picker Overlay

    private var languagePickerOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showingLanguagePicker = false }
                }

            VStack(spacing: 0) {
                Text(loc.string("language"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.bottom, 12)

                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    Button {
                        withAnimation {
                            loc.currentLanguage = lang
                            showingLanguagePicker = false
                        }
                    } label: {
                        HStack {
                            Text(lang.displayName)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                            Spacer()
                            if loc.currentLanguage == lang {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 4)
                    }
                    if lang != AppLanguage.allCases.last {
                        Divider()
                    }
                }
            }
            .padding(20)
            .frame(width: 220)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var fillLightBackground: some View {
        switch currentPreset.mode {
        case .solid:
            currentPreset.color.opacity(screenBrightness)
        case .gradientTopBottom:
            LinearGradient(
                colors: [currentPreset.color, currentPreset.secondColor],
                startPoint: .top,
                endPoint: .bottom
            ).opacity(screenBrightness)
        case .dualLeftRight:
            HStack(spacing: 0) {
                currentPreset.color
                currentPreset.secondColor
            }.opacity(screenBrightness)
        }
    }

    // MARK: - Viewfinder

    private var viewfinderArea: some View {
        ViewfinderPreview(cam: cam, isMirrored: isMirrored)
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .frame(width: viewfinderWidth, height: viewfinderHeight)
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.5), radius: 24, y: 12)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 14) {
            // Language button
            HStack {
                Spacer()
                languageButton
            }
            .padding(.trailing, 4)

            // Screen brightness slider
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 32, height: 32)
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 15))
                        .foregroundColor(currentPreset.color)
                }

                Slider(value: $screenBrightness, in: 0.0...1.0)
                    .tint(currentPreset.color)
                    .onChange(of: screenBrightness) { newValue in
                        UIScreen.main.brightness = newValue
                    }

                Text("\(Int(screenBrightness * 100))%")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(contrastColor)
                    .frame(width: 38, alignment: .trailing)
            }
            .padding(.horizontal, 4)

            HStack(spacing: 44) {
                // Preset
                Button { showingPresets = true } label: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(currentPreset.color)
                        .frame(width: 44, height: 44)
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                }

                // Shutter
                Button { triggerCapture() } label: {
                    ZStack {
                        Circle()
                            .stroke(contrastColor.opacity(0.3), lineWidth: 4)
                            .frame(width: 76, height: 76)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 62, height: 62)
                            .overlay(Circle().fill(currentPreset.color.opacity(0.08)))
                    }
                }
                .buttonStyle(ShutterButtonStyle())
                .disabled(!cam.isSessionReady)

                // Mirror toggle
                Button {
                    isMirrored.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.white.opacity(0.08))
                            .frame(width: 44, height: 44)

                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                            .frame(width: 44, height: 44)

                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(contrastColor)
                    }
                    .shadow(color: .black.opacity(0.25), radius: 10, y: 5)
                }
            }
        }
        .padding(.bottom, 48)
    }

    // MARK: - Preset Picker

    private var presetPicker: some View {
        ZStack {
            Color(white: 0.1).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text(loc.string("light_presets"))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if deleteMode {
                        Button {
                            withAnimation { deleteMode = false }
                        } label: {
                            Text("Done")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    Button {
                        showingPresets = false
                        deleteMode = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 48)

                Divider().background(Color.white.opacity(0.08))

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Built-in presets
                        Text(loc.string("built_in"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 16)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 12) {
                            ForEach(presets) { p in
                                presetCell(for: p, isCustom: false)
                                    .opacity(deleteMode ? 0.3 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: deleteMode)
                            }
                        }
                        .padding(.horizontal, 16)

                        // Custom presets
                        if !customPresets.isEmpty {
                            Text(loc.string("custom"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 16)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 12) {
                                ForEach(customPresets) { p in
                                    presetCell(for: p, isCustom: true)
                                        .overlay(deleteMode ? deleteOverlay(for: p) : nil)
                                        .animation(.easeInOut(duration: 0.2), value: deleteMode)
                                        .onLongPressGesture(minimumDuration: 0.4) {
                                            if !deleteMode {
                                                withAnimation { deleteMode = true }
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            }
                                        }
                                        .contextMenu {
                                            if !deleteMode {
                                                Button {
                                                    editCustomPreset(p)
                                                } label: {
                                                    Label("Edit Preset", systemImage: "pencil")
                                                }
                                                Button(role: .destructive) {
                                                    deleteCustomPreset(p)
                                                } label: {
                                                    Label(loc.string("delete_preset"), systemImage: "trash")
                                                }
                                            }
                                        }
                                }

                                // Add cell in grid
                                addPresetCell
                            }
                            .padding(.horizontal, 16)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 12) {
                                addPresetCell
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var addPresetCell: some View {
        Button {
            editingPreset = nil
            showingPresets = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingColorEditor = true
            }
        } label: {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                    .frame(height: 70)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .light))
                            .foregroundColor(.white.opacity(0.4))
                    }

                Text("Add")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                Text("Custom")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
    }

    @ViewBuilder
    private func deleteOverlay(for p: LightPreset) -> some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    withAnimation {
                        deleteCustomPreset(p)
                        if customPresets.isEmpty { deleteMode = false }
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.red).frame(width: 20, height: 20))
                        .shadow(radius: 4)
                }
                .padding(4)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func presetCell(for p: LightPreset, isCustom: Bool = false) -> some View {
        let isSelected = currentPresetId == p.id
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            currentPresetId = p.id
            showingPresets = false
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    presetSwatch(for: p)
                        .frame(height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isSelected && !deleteMode ? Color.white : .clear, lineWidth: 3)
                        )
                        .overlay(
                            deleteMode && isCustom ? Color.red.opacity(0.25) : Color.clear
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(deleteMode && isCustom ? Color.red.opacity(0.5) : .clear, lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        .scaleEffect(isSelected && !deleteMode ? 1.03 : 1.0)

                    // Selected checkmark
                    if isSelected && !deleteMode {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }

                    // Mode icon for gradient/dual
                    if p.mode != .solid {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: p.mode == .gradientTopBottom ? "square.fill.text.grid.1x2" : "square.split.2x1.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(4)
                                    .background(.black.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .padding(4)
                            }
                        }
                    }

                    // Custom preset badge
                    if p.isCustom {
                        VStack {
                            HStack {
                                Circle()
                                    .fill(Color.white.opacity(0.6))
                                    .frame(width: 5, height: 5)
                                    .padding(6)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isSelected)

                Text(loc.presetName(for: p))
                    .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if p.isCustom {
                    Text(modeLabel(p.mode))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }

    private func modeLabel(_ mode: PresetMode) -> String {
        switch mode {
        case .solid: return loc.string("mode_solid")
        case .gradientTopBottom: return loc.string("mode_gradient")
        case .dualLeftRight: return loc.string("mode_dual")
        }
    }

    private func editCustomPreset(_ p: LightPreset) {
        editingPreset = p
        showingPresets = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showingColorEditor = true
        }
    }

    @ViewBuilder
    private func presetSwatch(for p: LightPreset) -> some View {
        switch p.mode {
        case .solid:
            Rectangle().fill(p.color)
        case .gradientTopBottom:
            Rectangle().fill(
                LinearGradient(colors: [p.color, p.secondColor], startPoint: .top, endPoint: .bottom)
            )
        case .dualLeftRight:
            HStack(spacing: 0) {
                Rectangle().fill(p.color)
                Rectangle().fill(p.secondColor)
            }
        }
    }

    private func deleteCustomPreset(_ p: LightPreset) {
        withAnimation {
            customPresets.removeAll { $0.id == p.id }
            UserDefaults.standard.saveCustomPresets(customPresets)
            if currentPresetId == p.id {
                currentPresetId = 0
                screenBrightness = currentPreset.defaultScreenBrightness
                UIScreen.main.brightness = screenBrightness
            }
        }
    }

    // MARK: - Photo Preview

    private func photoPreview(_ image: UIImage) -> some View {
        GeometryReader { geo in
            Color.black.opacity(0.01).ignoresSafeArea()
                .onTapGesture { showingPreview = false }
                .overlay {
                    VStack(spacing: 14) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 180, height: 180 * 4 / 3)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        Text(loc.string("saved_to_library"))
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                    .transition(.scale.combined(with: .opacity))
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
        }
    }

    // MARK: - Actions

    private func triggerCapture() {
        guard cam.isSessionReady else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        cam.capture { result in
            switch result {
            case .success(let image):
                capturedImage = image
                withAnimation(.easeOut(duration: 0.25)) { showingPreview = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    if showingPreview { showingPreview = false }
                }
            case .failure:
                break
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Computed

    private var currentPreset: LightPreset {
        allPresets.first(where: { $0.id == currentPresetId }) ?? presets[0]
    }

    private func colorLuminance(_ color: UIColor) -> CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.299 * r + 0.587 * g + 0.114 * b
    }

    private var contrastColor: Color {
        let luminance: CGFloat
        switch currentPreset.mode {
        case .solid:
            luminance = colorLuminance(currentPreset.uiColor)
        case .gradientTopBottom, .dualLeftRight:
            let l1 = colorLuminance(currentPreset.uiColor)
            let l2 = colorLuminance(currentPreset.secondUIColor)
            luminance = (l1 + l2) / 2.0
        }
        let adjusted = luminance * screenBrightness
        return adjusted > 0.55 ? Color.black.opacity(0.55) : Color.white.opacity(0.75)
    }
}
