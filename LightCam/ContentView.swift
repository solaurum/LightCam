import SwiftUI

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var presetManager: PresetManager
    @EnvironmentObject var loc: LocalizationManager
    @ObservedObject var cam: CameraManager

    @State private var isMirrored = true
    @State private var capturedImage: UIImage?
    @State private var showingPreview = false
    @State private var showingPresets = false
    @State private var showingPermissionAlert = false
    @State private var showingLanguagePicker = false

    private let viewfinderWidth: CGFloat = 240
    private let viewfinderHeight: CGFloat = 240 * 4 / 3

    /// Non-optional accessor — guaranteed valid because builtInPresets always has ≥1 entry.
    private var preset: LightPreset {
        presetManager.currentPreset ?? presetManager.builtInPresets[0]
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                animeBackground
                    .ignoresSafeArea()

                fillLightBackground
                    .blendMode(.screen)
                    .animation(.easeInOut(duration: 0.35), value: presetManager.currentPresetId)
                    .contentShape(Rectangle())
                    .gesture(swipeGesture)

// Subtle colour atmosphere wash — synced with fill light animation
                preset.color
                    .opacity(0.06)
                    .blendMode(.screen)
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.35), value: presetManager.currentPresetId)


                VStack(spacing: 0) {
                    Spacer()
                    viewfinderArea
                    Spacer()
                    bottomControls
                }
                .padding(.bottom, geometry.safeAreaInsets.bottom + 8)

                if showingPreview, let img = capturedImage {
                    photoPreview(img, geometry: geometry)
                }

                if showingLanguagePicker {
                    languagePickerOverlay
                }

                if presetManager.showingColorEditor {
                    ZStack {
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                            .onTapGesture {
                                presetManager.closeEditor()
                            }

                        ColorPresetEditor()
                            .frame(height: geometry.size.height * 0.48)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                    .zIndex(100)
                }

                if showingPresets {
                    PresetPickerView(isPresented: $showingPresets)
                        .zIndex(101)
                }
            }
        }
        .ignoresSafeArea()
        .statusBar(hidden: true)
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

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                let horizontal = abs(value.translation.width)
                let vertical = abs(value.translation.height)
                guard horizontal > vertical else { return }

                let all = presetManager.allPresets
                guard let currentIdx = all.firstIndex(where: { $0.id == presetManager.currentPresetId }),
                      all.count > 1 else { return }

                if value.translation.width < 0, currentIdx > 0 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        presetManager.selectPreset(all[currentIdx - 1].id)
                    }
                    HapticHelper.light.fire()
                } else if value.translation.width > 0, currentIdx < all.count - 1 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        presetManager.selectPreset(all[currentIdx + 1].id)
                    }
                    HapticHelper.light.fire()
                }
            }
    }

    // MARK: - Anime Background

    private var animeBackground: some View {
        ZStack {
            LinearGradient(
                colors: [AnimeTheme.bgTop, AnimeTheme.bgMid, AnimeTheme.bgBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [AnimeTheme.magicalPurple.opacity(0.15), .clear],
                        center: .top,
                        startRadius: 20,
                        endRadius: 320
                    )
                )
                .frame(width: 360, height: 360)
                .position(x: UIScreen.main.bounds.width * 0.35, y: 80)
                .blur(radius: 40)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [AnimeTheme.sakura.opacity(0.10), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 280
                    )
                )
                .frame(width: 260, height: 260)
                .position(x: UIScreen.main.bounds.width * 0.75, y: 180)
                .blur(radius: 50)
        }
    }

    // MARK: - Fill Light Background

    @ViewBuilder
    private var fillLightBackground: some View {
        if let preset = presetManager.currentPreset {
            let brightness = presetManager.screenBrightness
            switch preset.mode {
            case .solid:
                preset.color.opacity(brightness)
            case .gradient:
                gradientBackground(preset).opacity(brightness)
            case .dual:
                dualBackground(preset).opacity(brightness)
            }
        }
    }

    @ViewBuilder
    private func gradientBackground(_ preset: LightPreset) -> some View {
        let (s, e) = preset.splitDirection.gradientPoints
        LinearGradient(colors: [preset.color, preset.secondColor], startPoint: s, endPoint: e)
    }

    @ViewBuilder
    private func dualBackground(_ preset: LightPreset) -> some View {
        let primary = preset.color
        let secondary = preset.secondColor
        switch preset.splitDirection {
        case .horizontal:
            HStack(spacing: 0) { primary; secondary }
        case .vertical:
            VStack(spacing: 0) { primary; secondary }
        case .diagonalLeft, .diagonalRight:
            let (s, e) = preset.splitDirection.gradientPoints
            LinearGradient(
                stops: [.init(color: primary, location: 0.48),
                        .init(color: secondary, location: 0.52)],
                startPoint: s, endPoint: e
            )
        }
    }

    // MARK: - Viewfinder

    private var viewfinderArea: some View {
        ViewfinderPreview(cam: cam, isMirrored: isMirrored)
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .frame(width: viewfinderWidth, height: viewfinderHeight)
            .shadow(color: preset.color.opacity(0.25), radius: 24, x: 0, y: 8)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            brightnessSlider
            HStack(spacing: 48) {
                presetButton
                shutterButton
                mirrorButton
            }
        }
        .padding(.bottom, 48)
    }

    // MARK: - Brightness Slider

    private var brightnessSlider: some View {
        let p = preset
        return VStack(spacing: 0) {
            // Language button — top-right of brightness bar
            HStack {
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showingLanguagePicker = true
                    }
                } label: {
                    Image(systemName: "globe")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.40))
                        .frame(width: 26, height: 26)
                        .background(.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .padding(.trailing, 2)
                .padding(.bottom, 2)
            }

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(p.color.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "sparkle")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(p.color)
                }
                .shadow(color: p.color.opacity(0.3), radius: 6, x: 0, y: 2)

                Slider(value: Binding(
                    get: { presetManager.screenBrightness },
                    set: { presetManager.setBrightness($0) }
                ), in: 0.0...1.0)
                .tint(
                    LinearGradient(
                        colors: [p.color.opacity(0.5), p.color],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

                Text("\(Int(presetManager.screenBrightness * 100))%")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(contrastColor)
                    .frame(width: 38, alignment: .trailing)
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Preset Button

    private var presetButton: some View {
        Button { withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { showingPresets = true } } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(preset.color.opacity(0.3))
                    .frame(width: 48, height: 48)
                    .blur(radius: 10)

                RoundedRectangle(cornerRadius: 12)
                    .fill(preset.color)
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear, .black.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(contrastColorForPreset(presetManager.currentPreset))
                    )
            }
            .shadow(color: preset.color.opacity(0.35), radius: 12, x: 0, y: 4)
        }
    }

    // MARK: - Shutter Button

    /// Cached lighter tint of the current preset colour — avoids UIColor conversion
    /// inside the view body on every render.  Invalidated only when the preset changes.
    @State private var cachedShutterTint: Color = .white

    private var shutterButton: some View {
        let p = preset
        return Button { triggerCapture() } label: {
            ZStack {
                // Angular gradient outer ring — harmonises with current preset
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [cachedShutterTint, p.color, cachedShutterTint],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 74, height: 74)
                    .shadow(color: p.color.opacity(0.35), radius: 10, x: 0, y: 3)

                // White button core
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.88)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "sparkle")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(p.color.opacity(0.35))
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .buttonStyle(AnimeShutterButtonStyle())
        .disabled(!cam.isSessionReady)
        .onAppear { cachedShutterTint = preset.primary.lighter() }
        .onChange(of: presetManager.currentPresetId) { _ in
            cachedShutterTint = preset.primary.lighter()
        }
    }

    // MARK: - Mirror Button

    private var mirrorButton: some View {
        Button {
            isMirrored.toggle()
            HapticHelper.light.fire()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(.white.opacity(0.06))
                    .frame(width: 48, height: 48)
                RoundedRectangle(cornerRadius: 13)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
                    .frame(width: 48, height: 48)
                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 17, weight: .light))
                    .foregroundColor(contrastColor.opacity(0.8))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isMirrored)
            }
            .shadow(color: preset.color.opacity(0.35), radius: 12, x: 0, y: 6)
        }
    }

    // MARK: - Language Picker

    private var languagePickerOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showingLanguagePicker = false
                    }
                }

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "sparkle")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AnimeTheme.starlight)
                    Text(loc.string("language"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                }
                .padding(.bottom, 14)

                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
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
                                Image(systemName: "sparkle")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AnimeTheme.starlight)
                                    .opacity(0.85)
                            }
                        }
                        .padding(.vertical, 13)
                        .padding(.horizontal, 4)
                    }
                    if lang != AppLanguage.allCases.last {
                        Divider().opacity(0.3)
                    }
                }
            }
            .padding(22)
            .frame(width: 230)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.35), radius: 30, y: 15)
        }
    }

    // MARK: - Photo Preview

    private func photoPreview(_ image: UIImage, geometry: GeometryProxy) -> some View {
        Color.black.opacity(0.01).ignoresSafeArea()
            .onTapGesture { showingPreview = false }
            .overlay {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AnimeTheme.starlight)
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AnimeTheme.magicalPurple)
                        Image(systemName: "sparkle")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AnimeTheme.starlight)
                    }

                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 180, height: 180 * 4 / 3)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: preset.color.opacity(0.3), radius: 20, x: 0, y: 8)

                    Text(loc.string("saved_to_library"))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(26)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.08), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 30, y: 15)
                .transition(.scale.combined(with: .opacity))
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
    }

    // MARK: - Capture

    private func triggerCapture() {
        guard cam.isSessionReady else { return }
        HapticHelper.heavy.fire()

        cam.capture { result in
            switch result {
            case .success(let image):
                capturedImage = image
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showingPreview = true
                }
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

    // MARK: - Helpers

    private var contrastColor: Color {
        let p = preset
        let lum: CGFloat
        switch p.mode {
        case .solid:
            lum = p.primary.luminance
        case .gradient, .dual:
            let l1 = p.primary.luminance
            let l2 = p.secondary.luminance
            lum = (l1 + l2) / 2.0
        }
        let adjusted = lum * CGFloat(presetManager.screenBrightness)
        return adjusted > 0.55 ? Color.black.opacity(0.55) : Color.white.opacity(0.75)
    }

    private func contrastColorForPreset(_ preset: LightPreset) -> Color {
        let lum = preset.primary.luminance
        return lum > 0.55 ? Color.black.opacity(0.5) : Color.white.opacity(0.85)
    }
}
