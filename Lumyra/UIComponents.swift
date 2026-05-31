import SwiftUI

// MARK: - Haptic Helper

extension UIImpactFeedbackGenerator {
    /// Fire the impact and immediately re-prepare so the next call is just as fast.
    func fire() {
        impactOccurred()
        prepare()
    }
}

/// Shared haptic generators — created lazily once and cached.
/// All views use these instead of duplicating generator instances.
enum HapticHelper {
    static var heavy: UIImpactFeedbackGenerator {
        struct Cache { static let instance: UIImpactFeedbackGenerator = {
            let g = UIImpactFeedbackGenerator(style: .heavy)
            g.prepare()
            return g
        }() }
        return Cache.instance
    }
    static var light: UIImpactFeedbackGenerator {
        struct Cache { static let instance: UIImpactFeedbackGenerator = {
            let g = UIImpactFeedbackGenerator(style: .light)
            g.prepare()
            return g
        }() }
        return Cache.instance
    }
    static var medium: UIImpactFeedbackGenerator {
        struct Cache { static let instance: UIImpactFeedbackGenerator = {
            let g = UIImpactFeedbackGenerator(style: .medium)
            g.prepare()
            return g
        }() }
        return Cache.instance
    }
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

/// Floating sparkle overlay used on the main screen and the preset picker.
struct AnimeSparkleView: View {
    @State private var particles: [SparkleParticle] = []

    let count: Int
    let color: Color

    /// Pre-generated particle cache — built once per count, reused across appearances.
    private static var particleCache: [Int: [SparkleParticle]] = [:]

    private static func particles(count: Int) -> [SparkleParticle] {
        if let cached = particleCache[count] { return cached }
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
        particleCache[count] = pts
        return pts
    }

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
                    // Core sparkle (diamond)
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
            particles = Self.particles(count: count)
        }
    }
}

// MARK: - Star Field (starry night sky)

/// A dense field of twinkling stars with a subtle Milky Way concentration.
/// Each star is a tiny glowing point; colours are drawn from the preset palette.
struct StarFieldView: View {
    struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat       // 0…1 normalised position
        let y: CGFloat
        let radius: CGFloat  // 0.4…2.2
        let color: Color
        let speed: Double    // twinkle frequency
        let phase: Double    // twinkle phase offset
        let glowAlpha: Double // base opacity
    }

    /// Pre-generated star field — built once per count, reused across appearances.
    private static var cache: [Int: [Star]] = [:]

    static func stars(count: Int = 80, palette: [Color] = AnimeTheme.fullPalette) -> [Star] {
        if let cached = cache[count] { return cached }
        var s: [Star] = []
        for i in 0..<count {
            let onBand = Double.random(in: 0...1) < 0.38
            let bx: CGFloat = .random(in: 0.05...0.95)
            let by: CGFloat = .random(in: 0.05...0.92)
            let bandY = (1.0 - bx) * 0.85 + 0.08
            let scatterY: CGFloat = .random(in: -0.10...0.10)
            let fy = onBand ? min(max(bandY + scatterY, 0.05), 0.92) : by
            s.append(Star(
                x: bx, y: fy,
                radius: .random(in: 0.4...2.2),
                color: palette[i % palette.count],
                speed: .random(in: 0.4...1.6),
                phase: .random(in: 0...(2 * .pi)),
                glowAlpha: .random(in: 0.15...0.55)
            ))
        }
        cache[count] = s
        return s
    }

    let stars: [Star]

    init(count: Int = 80, palette: [Color] = AnimeTheme.fullPalette) {
        stars = Self.stars(count: count, palette: palette)
    }

    init(stars: [Star]) { self.stars = stars }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSince1970
                for star in stars {
                    let twinkle = 0.35 + 0.65 * abs(sin(now * star.speed + star.phase))
                    let alpha = star.glowAlpha * twinkle
                    let cx = star.x * size.width
                    let cy = star.y * size.height
                    let r = star.radius

                    let glowRect = CGRect(x: cx - r * 2.2, y: cy - r * 2.2,
                                          width: r * 4.4, height: r * 4.4)
                    context.fill(Path(ellipseIn: glowRect),
                                 with: .color(star.color.opacity(alpha * 0.25)))
                    let coreRect = CGRect(x: cx - r, y: cy - r,
                                          width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: coreRect),
                                 with: .color(star.color.opacity(alpha)))
                }
            }
        }
        .blendMode(.screen)
        .allowsHitTesting(false)
    }
}

// MARK: - Star Flare (anime "kirakira" cross-shaped bright star)

/// A single anime-style bright star with 4-point diffraction spikes.
/// These are the iconic "kirakira" stars seen in anime night skies.
struct StarFlareView: View {
    let color: Color
    let size: CGFloat       // diameter of the central glow
    let spikeLength: CGFloat // how far the spikes extend
    let phaseOffset: Double

    @State private var twinkle: Double = 1.0

    var body: some View {
        ZStack {
            // ── Horizontal spike ──
            Capsule()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: color.opacity(0.9 * twinkle), location: 0.25),
                            .init(color: .white.opacity(0.7 * twinkle), location: 0.5),
                            .init(color: color.opacity(0.9 * twinkle), location: 0.75),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(width: spikeLength * 2, height: size * 0.12)

            // ── Vertical spike ──
            Capsule()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: color.opacity(0.9 * twinkle), location: 0.25),
                            .init(color: .white.opacity(0.7 * twinkle), location: 0.5),
                            .init(color: color.opacity(0.9 * twinkle), location: 0.75),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: size * 0.12, height: spikeLength * 2)

            // ── Diagonal spikes (shorter) ──
            Capsule()
                .fill(color.opacity(0.4 * twinkle))
                .frame(width: spikeLength * 1.0, height: size * 0.06)
                .rotationEffect(.degrees(45))
            Capsule()
                .fill(color.opacity(0.4 * twinkle))
                .frame(width: spikeLength * 1.0, height: size * 0.06)
                .rotationEffect(.degrees(-45))

            // ── Central glow ──
            Circle()
                .fill(RadialGradient(
                    colors: [.white.opacity(0.85 * twinkle), color.opacity(0.5 * twinkle), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.55
                ))
                .frame(width: size * 0.55, height: size * 0.55)
        }
        .blendMode(.screen)
        .onAppear {
            withAnimation(
                .easeInOut(duration: .random(in: 1.8...3.2))
                .repeatForever(autoreverses: true)
                .delay(phaseOffset)
            ) {
                twinkle = 0.25
            }
        }
    }
}

// MARK: - Anime Starry Background (reusable)

/// A clean, minimalist starry-sky background shared by the preset picker
/// and the colour editor.  Features a Milky Way ribbon, a sparse twinkling
/// star field, three subtle accent flares, and two soft nebula glows.
///
/// Layout positions are derived from screen bounds once at init and cached;
/// the View body is a pure function of those cached values — no live
/// `UIScreen.main.bounds` calls during layout.
struct AnimeStarryBackground: View {
    private let screenW: CGFloat
    private let screenH: CGFloat
    private let palette: [Color]

    init() {
        let bounds = UIScreen.main.bounds
        screenW = bounds.width
        screenH = bounds.height
        palette = AnimeTheme.presetPalette
    }

    var body: some View {
        ZStack {
            // ── Deep space ──────────────────────────────────────────
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.02, blue: 0.10),
                    Color(red: 0.05, green: 0.03, blue: 0.13),
                    Color(red: 0.02, green: 0.01, blue: 0.08),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // ── Milky Way ribbon ────────────────────────────────────
            LinearGradient(
                colors: palette,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.08)
            .blendMode(.screen)
            .blur(radius: 45)

            // ── Star field (reduced count for perf) ─────────────────
            StarFieldView(count: 18, palette: palette)

            // ── Accent flares ───────────────────────────────────────
            starFlare(color: palette[1], x: 0.22, y: 0.10, size: 12, spike: 22, delay: 0.0)
            starFlare(color: palette[4], x: 0.78, y: 0.22, size: 10, spike: 18, delay: 1.2)
            starFlare(color: palette[7], x: 0.48, y: 0.76, size: 11, spike: 20, delay: 0.6)

            // ── Nebula: top-right pink ──────────────────────────────
            Circle()
                .fill(RadialGradient(
                    colors: [AnimeTheme.sakura.opacity(0.05), .clear],
                    center: .center, startRadius: 10, endRadius: 240
                ))
                .frame(width: 260, height: 260)
                .position(x: screenW * 0.72, y: screenH * 0.10)
                .blur(radius: 50)
                .blendMode(.screen)
                .drawingGroup()

            // ── Nebula: bottom-left teal ────────────────────────────
            Circle()
                .fill(RadialGradient(
                    colors: [AnimeTheme.nightGlow.opacity(0.04), .clear],
                    center: .center, startRadius: 10, endRadius: 200
                ))
                .frame(width: 240, height: 240)
                .position(x: screenW * 0.25, y: screenH * 0.70)
                .blur(radius: 50)
                .blendMode(.screen)
                .drawingGroup()
        }
        .drawingGroup()
    }

    @ViewBuilder
    private func starFlare(
        color: Color,
        x: CGFloat, y: CGFloat,
        size: CGFloat,
        spike: CGFloat,
        delay: Double
    ) -> some View {
        StarFlareView(color: color, size: size, spikeLength: spike, phaseOffset: delay)
            .frame(width: spike * 2, height: spike * 2)
            .position(x: screenW * x, y: screenH * y)
    }
}

// MARK: - Galaxy Background

/// Deep-space nebula background — dark purple-blue #1A1030 base
/// with layered nebula glows and scattered distant stars.
struct GalaxyBackground: View {
    private let baseColor = Color(red: 0.102, green: 0.063, blue: 0.188) // #1A1030

    var body: some View {
        ZStack {
            // ── Base: deep purple-blue ────────────────────────────
            baseColor

            // ── Large soft nebula: centre-right indigo ────────────
            RadialGradient(
                colors: [
                    Color(red: 0.259, green: 0.157, blue: 0.471).opacity(0.55),
                    .clear
                ],
                center: UnitPoint(x: 0.55, y: 0.45),
                startRadius: 40,
                endRadius: 340
            )
            .blendMode(.screen)

            // ── Nebula: top-left cool violet ──────────────────────
            RadialGradient(
                colors: [
                    Color(red: 0.353, green: 0.220, blue: 0.549).opacity(0.35),
                    .clear
                ],
                center: UnitPoint(x: 0.22, y: 0.25),
                startRadius: 20,
                endRadius: 280
            )
            .blendMode(.screen)

            // ── Nebula: bottom-right warm purple ──────────────────
            RadialGradient(
                colors: [
                    Color(red: 0.420, green: 0.180, blue: 0.420).opacity(0.30),
                    .clear
                ],
                center: UnitPoint(x: 0.80, y: 0.75),
                startRadius: 10,
                endRadius: 300
            )
            .blendMode(.screen)

            // ── Subtle core glow: upper-centre blue-violet ────────
            RadialGradient(
                colors: [
                    Color(red: 0.220, green: 0.145, blue: 0.420).opacity(0.40),
                    .clear
                ],
                center: UnitPoint(x: 0.40, y: 0.35),
                startRadius: 30,
                endRadius: 400
            )
            .blendMode(.screen)

            // ── Darkened edges (vignette) ─────────────────────────
            RadialGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.35)
                ],
                center: .center,
                startRadius: 180,
                endRadius: 420
            )

            // ── Distant stars ─────────────────────────────────────
            Canvas { context, size in
                let starColors: [Color] = [
                    Color(red: 0.910, green: 0.835, blue: 1.0),   // #E8D5FF lavender
                    Color(red: 0.780, green: 0.780, blue: 0.960), // cool white-blue
                    Color(red: 0.890, green: 0.780, blue: 0.950), // pale violet
                ]
                let stars: [(x: CGFloat, y: CGFloat, r: CGFloat, opacity: Double)] = [
                    (0.08, 0.12, 1.2, 0.55),
                    (0.35, 0.18, 0.8, 0.40),
                    (0.72, 0.22, 1.5, 0.60),
                    (0.55, 0.38, 1.0, 0.45),
                    (0.18, 0.48, 0.7, 0.35),
                    (0.85, 0.50, 1.1, 0.50),
                    (0.42, 0.62, 0.9, 0.40),
                    (0.68, 0.72, 1.3, 0.55),
                    (0.22, 0.78, 0.6, 0.30),
                    (0.90, 0.85, 1.0, 0.45),
                    (0.15, 0.35, 0.5, 0.25),
                    (0.50, 0.82, 0.8, 0.35),
                    (0.78, 0.10, 0.7, 0.30),
                    (0.60, 0.55, 1.4, 0.55),
                    (0.32, 0.70, 0.6, 0.28),
                    (0.05, 0.60, 0.9, 0.38),
                    (0.95, 0.35, 0.5, 0.22),
                    (0.44, 0.08, 0.4, 0.20),
                ]
                for star in stars {
                    let color = starColors.randomElement() ?? starColors[0]
                    let rect = CGRect(
                        x: star.x * size.width - star.r,
                        y: star.y * size.height - star.r,
                        width: star.r * 2,
                        height: star.r * 2
                    )
                    // Soft glow
                    let glowRect = rect.insetBy(dx: -star.r, dy: -star.r)
                    context.fill(
                        Path(ellipseIn: glowRect),
                        with: .color(color.opacity(star.opacity * 0.25))
                    )
                    // Core
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(color.opacity(star.opacity))
                    )
                }
            }
            .allowsHitTesting(false)
        }
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
