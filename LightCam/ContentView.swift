import SwiftUI

// MARK: - Anime Theme Constants

private enum AnimeTheme {
    // Background
    static let bgTop = Color(red: 0.06, green: 0.04, blue: 0.14)       // deep navy-indigo
    static let bgMid = Color(red: 0.08, green: 0.05, blue: 0.16)
    static let bgBottom = Color(red: 0.04, green: 0.02, blue: 0.10)

    // Accent — harmonized with preset palette
    static let sakura = Color(red: 0.949, green: 0.627, blue: 0.710)    // #F2A0B5
    static let starlight = Color(red: 1.0, green: 0.835, blue: 0.55)    // gold sparkle
    static let magicalPurple = Color(red: 0.706, green: 0.573, blue: 0.878) // #B492E0
    static let nightGlow = Color(red: 0.353, green: 0.620, blue: 0.714)  // #5A9EB6

    // Surfaces
    static let cardBg = Color.white.opacity(0.05)
    static let cardBorder = Color.white.opacity(0.08)
    static let glowSoft = Color.white.opacity(0.04)
}

// MARK: - Sparkle Particle System

struct SparkleParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var speed: Double
    var phase: Double
}

struct AnimeSparkleView: View {
    @State private var particles: [SparkleParticle] = []
    @State private var timer: Timer?

    let count: Int
    let color: Color

    init(count: Int = 18, color: Color = AnimeTheme.starlight) {
        self.count = count
        self.color = color
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSince1970
                for p in particles {
                    let floatY = sin(now * p.speed + p.phase) * 15
                    let floatX = cos(now * p.speed * 0.7 + p.phase) * 8
                    let alpha = p.opacity * (0.4 + 0.6 * abs(sin(now * p.speed * 1.3 + p.phase)))

                    let rect = CGRect(
                        x: p.x * size.width + floatX,
                        y: p.y * size.height + floatY,
                        width: 3 * p.scale,
                        height: 3 * p.scale
                    )

                    // Glow layer
                    context.fill(
                        Path(ellipseIn: rect.insetBy(dx: -2, dy: -2)),
                        with: .color(color.opacity(alpha * 0.3))
                    )
                    // Core sparkle (4-point star approximated as diamond)
                    let cx = rect.midX; let cy = rect.midY; let r = rect.width / 2
                    var diamond = Path()
                    diamond.move(to: CGPoint(x: cx, y: cy - r))
                    diamond.addLine(to: CGPoint(x: cx + r * 0.4, y: cy))
                    diamond.addLine(to: CGPoint(x: cx, y: cy + r))
                    diamond.addLine(to: CGPoint(x: cx - r * 0.4, y: cy))
                    diamond.closeSubpath()
                    context.fill(diamond, with: .color(color.opacity(alpha)))
                }
            }
        }
        .onAppear {
            var pts: [SparkleParticle] = []
            for _ in 0..<count {
                pts.append(SparkleParticle(
                    x: .random(in: 0.05...0.95),
                    y: .random(in: 0.08...0.92),
                    scale: .random(in: 0.5...1.6),
                    opacity: .random(in: 0.3...0.9),
                    speed: .random(in: 0.3...1.0),
                    phase: .random(in: 0...(2 * .pi))
                ))
            }
            particles = pts
        }
    }
}

// MARK: - Star Corner Decoration

struct StarCorners: View {
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            // Top-left
            starIcon
                .position(x: size / 2, y: size / 2)
            // Top-right
            starIcon
                .position(x: size - size / 2, y: size / 2)
            // Bottom-left
            starIcon
                .position(x: size / 2, y: size - size / 2)
            // Bottom-right
            starIcon
                .position(x: size - size / 2, y: size - size / 2)
        }
    }

    private var starIcon: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(color.opacity(0.6))
    }
}

// MARK: - Glowing Border

struct GlowingBorder: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.5), color.opacity(0.12), color.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: color.opacity(0.25), radius: 16, x: 0, y: 4)
    }
}

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
        // 1. 樱花微醺粉 #F2A0B5 — 柔雾玫瑰粉，少女感氛围自拍
        LightPreset(id: 0, name: "樱花微醺粉",  red: 0.949, green: 0.627, blue: 0.710, temp: 3800, defaultScreenBrightness: 0.86),
        // 2. 黄金时刻奶黄 #FFB680 — 蜜桃暖金，模拟黄金小时柔光
        LightPreset(id: 1, name: "黄金时刻奶黄", red: 1.0,   green: 0.714, blue: 0.502, temp: 3400, defaultScreenBrightness: 0.90),
        // 3. 极光紫薰衣草 #B492E0 — 梦幻极光紫，赛博创意拍摄
        LightPreset(id: 2, name: "极光紫薰衣草", red: 0.706, green: 0.573, blue: 0.878, temp: 6000, defaultScreenBrightness: 0.76),
        // 4. 珊瑚礁蜜桃 #FF9580 — 元气珊瑚橘，活力夏日通透感
        LightPreset(id: 3, name: "珊瑚礁蜜桃",   red: 1.0,   green: 0.584, blue: 0.502, temp: 4200, defaultScreenBrightness: 0.84),
        // 5. 冰川蓝冰白 #AADCF2 — 冰晶天蓝，清冷高级冬日氛围
        LightPreset(id: 4, name: "冰川蓝冰白",   red: 0.667, green: 0.863, blue: 0.949, temp: 7200, defaultScreenBrightness: 0.80),
        // 6. 抹茶雾浅绿 #BAD0A2 — 抹茶草绿，清新自然ins风
        LightPreset(id: 5, name: "抹茶雾浅绿",   red: 0.729, green: 0.816, blue: 0.635, temp: 5200, defaultScreenBrightness: 0.78),
        // 7. 烟灰银珍珠白 #D2C8BF — 暖调珍珠灰，极简高冷商务感
        LightPreset(id: 6, name: "烟灰银珍珠白", red: 0.824, green: 0.784, blue: 0.749, temp: 5800, defaultScreenBrightness: 0.88),
        // 8. 深海夜光深蓝 #5A9EB6 — 深海青蓝渐变，夜拍神秘氛围
        LightPreset(id: 7, name: "深海夜光深蓝", red: 0.353, green: 0.620, blue: 0.714, temp: 7800, defaultScreenBrightness: 0.70,
                    mode: .dualLeftRight, secondRed: 0.18, secondGreen: 0.35, secondBlue: 0.55),
    ]

    private var allPresets: [LightPreset] { presets + customPresets }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // MARK: - Anime Night Sky Background
                animeBackground
                    .ignoresSafeArea()

                // Sparkle particles
                AnimeSparkleView(count: 16, color: AnimeTheme.starlight)
                    .allowsHitTesting(false)

                // Fill light overlay
                fillLightBackground
                    .animation(.easeInOut(duration: 0.35), value: currentPresetId)
                    .simultaneousGesture(swipeGesture)

                // Color brightness overlay
                currentPreset.color
                    .opacity(currentPreset.defaultColorBrightness * 0.25)

                // Language — top-right, standard iOS position
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showingLanguagePicker = true
                            }
                        } label: {
                            Image(systemName: "globe")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.45))
                                .frame(width: 32, height: 32)
                                .background(.white.opacity(0.06))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                        .padding(.top, geometry.safeAreaInsets.top + 8)
                    }
                    Spacer()
                }

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

                // MARK: - Color Editor Bottom Panel (no dimming, edge-to-edge)
                if showingColorEditor {
                    ColorPresetEditor(customPresets: $customPresets, isPresented: $showingColorEditor,
                                      editingPreset: editingPreset)
                        .environmentObject(loc)
                        .frame(height: geometry.size.height * 0.5)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .transition(.move(edge: .bottom))
                        .zIndex(100)
                }
            }
        }
        .ignoresSafeArea()
        .statusBar(hidden: true)
        .onAppear {
            customPresets = UserDefaults.standard.loadCustomPresets()
            screenBrightness = currentPreset.defaultScreenBrightness
            UIScreen.main.brightness = screenBrightness
        }
        .onChange(of: currentPresetId) { _ in
            screenBrightness = currentPreset.defaultScreenBrightness
            UIScreen.main.brightness = screenBrightness
        }
        .fullScreenCover(isPresented: $showingPresets) { presetPicker }
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

                let all = allPresets
                guard let currentIdx = all.firstIndex(where: { $0.id == currentPresetId }),
                      all.count > 1 else { return }

                if value.translation.width < 0, currentIdx < all.count - 1 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        currentPresetId = all[currentIdx + 1].id
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } else if value.translation.width > 0, currentIdx > 0 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        currentPresetId = all[currentIdx - 1].id
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }

    // MARK: - Anime Background

    private var animeBackground: some View {
        ZStack {
            // Base gradient — deep night sky
            LinearGradient(
                colors: [AnimeTheme.bgTop, AnimeTheme.bgMid, AnimeTheme.bgBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            // Subtle starlight glow at top
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

            // Secondary glow — sakura pink
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

    // MARK: - Background Fill Light

    @ViewBuilder
    private var fillLightBackground: some View {
        switch currentPreset.mode {
        case .solid:
            currentPreset.color.opacity(screenBrightness)
        case .gradientTopBottom:
            gradientBackground
                .opacity(screenBrightness)
        case .dualLeftRight:
            dualBackground
                .opacity(screenBrightness)
        }
    }

    @ViewBuilder
    private var gradientBackground: some View {
        let primary = currentPreset.color
        let secondary = currentPreset.secondColor
        let dir = currentPreset.splitDirection

        switch dir {
        case .horizontal:
            LinearGradient(colors: [primary, secondary], startPoint: .top, endPoint: .bottom)
        case .vertical:
            LinearGradient(colors: [primary, secondary], startPoint: .leading, endPoint: .trailing)
        case .diagonalLeft:
            LinearGradient(colors: [primary, secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .diagonalRight:
            LinearGradient(colors: [primary, secondary], startPoint: .topTrailing, endPoint: .bottomLeading)
        }
    }

    @ViewBuilder
    private var dualBackground: some View {
        let primary = currentPreset.color
        let secondary = currentPreset.secondColor
        let dir = currentPreset.splitDirection

        switch dir {
        case .horizontal:
            HStack(spacing: 0) {
                primary; secondary
            }
        case .vertical:
            VStack(spacing: 0) {
                primary; secondary
            }
        case .diagonalLeft:
            LinearGradient(
                stops: [
                    .init(color: primary, location: 0.48),
                    .init(color: secondary, location: 0.52),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .diagonalRight:
            LinearGradient(
                stops: [
                    .init(color: primary, location: 0.48),
                    .init(color: secondary, location: 0.52),
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }

    // MARK: - Viewfinder Area

    private var viewfinderArea: some View {
        ViewfinderPreview(cam: cam, isMirrored: isMirrored)
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .frame(width: viewfinderWidth, height: viewfinderHeight)
            .shadow(color: currentPreset.color.opacity(0.25), radius: 24, x: 0, y: 8)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Screen brightness slider — themed
            brightnessSlider

            // Control buttons row
            HStack(spacing: 48) {
                // Preset picker button
                presetButton

                // Shutter button
                shutterButton

                // Mirror toggle button
                mirrorButton
            }
        }
        .padding(.bottom, 48)
    }

    // MARK: - Brightness Slider

    private var brightnessSlider: some View {
        HStack(spacing: 12) {
            // Star icon with glow
            ZStack {
                Circle()
                    .fill(currentPreset.color.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: "sparkle")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(currentPreset.color)
            }
            .shadow(color: currentPreset.color.opacity(0.3), radius: 6, x: 0, y: 2)

            // Gradient slider track
            Slider(value: $screenBrightness, in: 0.0...1.0)
                .tint(
                    LinearGradient(
                        colors: [currentPreset.color.opacity(0.5), currentPreset.color],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .onChange(of: screenBrightness) { newValue in
                    UIScreen.main.brightness = newValue
                }

            // Percentage label
            Text("\(Int(screenBrightness * 100))%")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(contrastColor)
                .frame(width: 38, alignment: .trailing)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Preset Button

    private var presetButton: some View {
        Button { showingPresets = true } label: {
            ZStack {
                // Glow
                RoundedRectangle(cornerRadius: 13)
                    .fill(currentPreset.color.opacity(0.3))
                    .frame(width: 48, height: 48)
                    .blur(radius: 10)

                // Color swatch
                RoundedRectangle(cornerRadius: 12)
                    .fill(currentPreset.color)
                    .frame(width: 44, height: 44)
                    .overlay(
                        // Subtle inner gradient for depth
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
                        // Sparkle icon
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(
                                contrastColorForPreset(currentPreset)
                            )
                    )
            }
            .shadow(color: currentPreset.color.opacity(0.35), radius: 12, x: 0, y: 4)
        }
    }

    // MARK: - Shutter Button

    private var shutterButton: some View {
        Button { triggerCapture() } label: {
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [currentPreset.color.opacity(0.7), AnimeTheme.starlight.opacity(0.4),
                                     currentPreset.color.opacity(0.7)],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: currentPreset.color.opacity(0.3), radius: 14, x: 0, y: 4)

                // Inner ring
                Circle()
                    .stroke(contrastColor.opacity(0.18), lineWidth: 1.5)
                    .frame(width: 70, height: 70)

                // Solid center
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
                        // Subtle star in center
                        Image(systemName: "sparkle")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(currentPreset.color.opacity(0.35))
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                // Inner highlight ring
                Circle()
                    .stroke(currentPreset.color.opacity(0.12), lineWidth: 1)
                    .frame(width: 58, height: 58)
            }
        }
        .buttonStyle(AnimeShutterButtonStyle())
        .disabled(!cam.isSessionReady)
    }

    // MARK: - Mirror Button

    private var mirrorButton: some View {
        Button {
            isMirrored.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 13)
                    .fill(.white.opacity(0.06))
                    .frame(width: 48, height: 48)

                // Border
                RoundedRectangle(cornerRadius: 13)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
                    .frame(width: 48, height: 48)

                // Icon
                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 17, weight: .light))
                    .foregroundColor(contrastColor.opacity(0.8))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isMirrored)
            }
            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
        }
    }

    // MARK: - Language Button

    private var languageButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showingLanguagePicker.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .font(.system(size: 10, weight: .semibold))
                Text(loc.currentLanguage.shortName)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundColor(contrastColor.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.white.opacity(0.06))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.08), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Language Picker Overlay

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
                // Header with sparkle
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

    // MARK: - Preset Picker (Full Screen)

    private var presetPicker: some View {
        ZStack {
            // Anime-themed background
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.04, blue: 0.12), Color(red: 0.03, green: 0.02, blue: 0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle sparkles
            AnimeSparkleView(count: 8, color: AnimeTheme.magicalPurple)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AnimeTheme.starlight)
                        Text(loc.string("light_presets"))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Spacer()

                    if deleteMode {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                deleteMode = false
                            }
                        } label: {
                            Text("Done")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    Button {
                        showingPresets = false
                        deleteMode = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 18)
                .frame(height: 52)

                Divider().background(Color.white.opacity(0.06))

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Built-in section
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(AnimeTheme.starlight.opacity(0.7))
                            Text(loc.string("built_in"))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.45))
                        }
                        .padding(.horizontal, 18)

                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 82), spacing: 14)],
                            spacing: 14
                        ) {
                            ForEach(presets) { p in
                                animePresetCell(for: p, isCustom: false)
                                    .opacity(deleteMode ? 0.3 : 1.0)
                                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: deleteMode)
                            }
                        }
                        .padding(.horizontal, 18)

                        // Custom section
                        if !customPresets.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(AnimeTheme.sakura.opacity(0.7))
                                Text(loc.string("custom"))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.45))
                            }
                            .padding(.horizontal, 18)

                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 82), spacing: 14)],
                                spacing: 14
                            ) {
                                ForEach(customPresets) { p in
                                    animePresetCell(for: p, isCustom: true)
                                        .overlay(deleteMode ? deleteOverlay(for: p) : nil)
                                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: deleteMode)
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
                                addPresetCell
                            }
                            .padding(.horizontal, 18)
                        } else {
                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 82), spacing: 14)],
                                spacing: 14
                            ) {
                                addPresetCell
                            }
                            .padding(.horizontal, 18)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Add Preset Cell

    private var addPresetCell: some View {
        Button {
            editingPreset = nil
            showingPresets = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showingColorEditor = true
                }
            }
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [AnimeTheme.magicalPurple.opacity(0.3), AnimeTheme.sakura.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 3])
                    )
                    .frame(height: 72)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(AnimeTheme.magicalPurple.opacity(0.5))
                    }

                Text("New")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
    }

    // MARK: - Delete Overlay

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

    // MARK: - Anime Preset Cell

    @ViewBuilder
    private func animePresetCell(for p: LightPreset, isCustom: Bool = false) -> some View {
        let isSelected = currentPresetId == p.id
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                currentPresetId = p.id
            }
            showingPresets = false
        } label: {
            VStack(spacing: 7) {
                ZStack {
                    // Swatch background
                    presetSwatch(for: p)
                        .frame(height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Selected glow border
                    if isSelected && !deleteMode {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                AngularGradient(
                                    colors: [AnimeTheme.starlight, p.color, AnimeTheme.starlight],
                                    center: .center
                                ),
                                lineWidth: 2.5
                            )
                            .shadow(color: p.color.opacity(0.5), radius: 8, x: 0, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.06), lineWidth: 0.5)
                    }

                    // Delete overlay
                    if deleteMode && isCustom {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.red.opacity(0.2))
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.4), lineWidth: 2)
                    }

                    // Sparkle badge for selected
                    if isSelected && !deleteMode {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "sparkle")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(AnimeTheme.starlight)
                                    .padding(6)
                                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 1)
                            }
                            Spacer()
                        }
                    }

                    // Mode icon for gradient/dual
                    if p.mode != .solid {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                modeBadgeIcon(for: p)
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(3)
                                    .background(.black.opacity(0.25))
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                                    .padding(4)
                            }
                        }
                    }

                    // Custom badge
                    if p.isCustom {
                        VStack {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 7))
                                    .foregroundColor(AnimeTheme.sakura.opacity(0.8))
                                    .padding(6)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
                .scaleEffect(isSelected && !deleteMode ? 1.04 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)

                // Preset name
                Text(loc.presetName(for: p))
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    .lineLimit(1)

                // Mode label for custom
                if p.isCustom {
                    Text(modeLabel(p.mode))
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.35))
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

    private func modeBadgeIcon(for p: LightPreset) -> Image {
        switch p.splitDirection {
        case .horizontal:    return Image(systemName: p.mode == .gradientTopBottom ? "rectangle.split.2x1.fill" : "rectangle.split.1x2.fill")
        case .vertical:      return Image(systemName: p.mode == .gradientTopBottom ? "rectangle.split.1x2.fill" : "rectangle.split.2x1.fill")
        case .diagonalLeft:  return Image(systemName: "triangle.split.2x1")
        case .diagonalRight: return Image(systemName: "triangle.split.1x2")
        }
    }

    private func editCustomPreset(_ p: LightPreset) {
        editingPreset = p
        showingPresets = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showingColorEditor = true
            }
        }
    }

    @ViewBuilder
    private func presetSwatch(for p: LightPreset) -> some View {
        switch p.mode {
        case .solid:
            Rectangle().fill(p.color)
        case .gradientTopBottom:
            gradientSwatch(primary: p.color, secondary: p.secondColor, direction: p.splitDirection)
        case .dualLeftRight:
            dualSwatch(primary: p.color, secondary: p.secondColor, direction: p.splitDirection)
        }
    }

    @ViewBuilder
    private func gradientSwatch(primary: Color, secondary: Color, direction: SplitDirection) -> some View {
        switch direction {
        case .horizontal:
            Rectangle().fill(LinearGradient(colors: [primary, secondary], startPoint: .top, endPoint: .bottom))
        case .vertical:
            Rectangle().fill(LinearGradient(colors: [primary, secondary], startPoint: .leading, endPoint: .trailing))
        case .diagonalLeft:
            Rectangle().fill(LinearGradient(colors: [primary, secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .diagonalRight:
            Rectangle().fill(LinearGradient(colors: [primary, secondary], startPoint: .topTrailing, endPoint: .bottomLeading))
        }
    }

    @ViewBuilder
    private func dualSwatch(primary: Color, secondary: Color, direction: SplitDirection) -> some View {
        switch direction {
        case .horizontal:
            HStack(spacing: 0) {
                Rectangle().fill(primary)
                Rectangle().fill(secondary)
            }
        case .vertical:
            VStack(spacing: 0) {
                Rectangle().fill(primary)
                Rectangle().fill(secondary)
            }
        case .diagonalLeft:
            Rectangle().fill(
                LinearGradient(
                    stops: [
                        .init(color: primary, location: 0.48),
                        .init(color: secondary, location: 0.52),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .diagonalRight:
            Rectangle().fill(
                LinearGradient(
                    stops: [
                        .init(color: primary, location: 0.48),
                        .init(color: secondary, location: 0.52),
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
            )
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
                    VStack(spacing: 12) {
                        // Sparkle decoration
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

                        // Photo
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 180, height: 180 * 4 / 3)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.white.opacity(0.12), lineWidth: 1)
                            )
                            .shadow(color: currentPreset.color.opacity(0.3), radius: 20, x: 0, y: 8)

                        // Saved label
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

    // MARK: - Computed Helpers

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

    private func contrastColorForPreset(_ preset: LightPreset) -> Color {
        let lum = colorLuminance(preset.uiColor)
        return lum > 0.55 ? Color.black.opacity(0.5) : Color.white.opacity(0.85)
    }
}

// MARK: - Anime Shutter Button Style

struct AnimeShutterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.91 : 1.0)
            .shadow(
                color: .black.opacity(configuration.isPressed ? 0.1 : 0.35),
                radius: configuration.isPressed ? 6 : 16,
                y: configuration.isPressed ? 3 : 6
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
