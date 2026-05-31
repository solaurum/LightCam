import SwiftUI

// MARK: - Preset Picker (Full-Screen Cover)

struct PresetPickerView: View {
    @EnvironmentObject var presetManager: PresetManager
    @EnvironmentObject var loc: LocalizationManager

    @Binding var isPresented: Bool
    @State private var deleteMode = false

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                GalaxyBackground()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // Floating sparkles
                AnimeSparkleView(count: 10, color: AnimeTheme.starlight)
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    header
                        .padding(.top, max(geo.safeAreaInsets.top, 8))
                        .background(headerBackground.ignoresSafeArea(edges: .top))
                    presetGrid
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 0) {
            // Title
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AnimeTheme.starlight)
                Text(loc.string("light_presets"))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            // Delete-mode Done button
            if deleteMode {
                Button {
                    deleteMode = false
                } label: {
                    Text("Done")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(AnimeTheme.starlight.opacity(0.22))
                        )
                }
                .padding(.trailing, 10)
            }

            // Close button
            Button {
                isPresented = false
                deleteMode = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.1))
                    )
            }
            .contentShape(Circle())
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
    }

    /// Glass-morphism header with subtle warm gradient and bottom hairline.
    private var headerBackground: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            // Subtle warm glow at bottom edge
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            AnimeTheme.starlight.opacity(0.03),
                            .clear,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Bottom hairline
            VStack {
                Spacer()
                Rectangle()
                    .fill(.white.opacity(0.06))
                    .frame(height: 0.5)
            }
        }
    }

    // MARK: - Grid Content

    private var presetGrid: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // -- Built-in section --
                sectionHeader(icon: "star.fill", color: AnimeTheme.starlight,
                              title: loc.string("built_in"))
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 80), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(presetManager.builtInPresets) { p in
                        presetCell(for: p, isCustom: false)
                            .opacity(deleteMode ? 0.35 : 1.0)
                            .scaleEffect(deleteMode ? 0.96 : 1.0)
                    }
                }
                .padding(.horizontal, 20)

                // -- Decorative divider --
                sectionDivider

                // -- Custom section --
                sectionHeader(icon: "heart.fill", color: AnimeTheme.sakura,
                              title: loc.string("custom"))

                if presetManager.customPresets.isEmpty {
                    // Empty state: centred add button
                    HStack {
                        Spacer()
                        addPresetCell
                            .frame(width: 84)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 80), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(presetManager.customPresets) { p in
                            presetCell(for: p, isCustom: true)
                                .overlay(deleteMode ? deleteOverlay(for: p) : nil)
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
                                .onLongPressGesture(minimumDuration: 0.4) {
                                    if !deleteMode {
                                        deleteMode = true
                                        HapticHelper.medium.fire()
                                    }
                                }
                        }
                        addPresetCell
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 24)
        }
        .mask(scrollFadeMask)
    }

    /// Fades the top edge so content disappears softly behind the glass header.
    private var scrollFadeMask: some View {
        VStack(spacing: 0) {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.06),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            Color.black
        }
    }

    // MARK: - Section Header

    /// Capsule-style badge for each section.
    private func sectionHeader(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(color.opacity(0.15), lineWidth: 0.5)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Section Divider

    /// Thin line with a tiny sparkle in the centre, bridging the two sections.
    private var sectionDivider: some View {
        HStack(spacing: 0) {
            Color.white.opacity(0.04)
                .frame(height: 0.5)
                .frame(maxWidth: .infinity)
            Image(systemName: "sparkle")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(AnimeTheme.starlight.opacity(0.25))
                .padding(.horizontal, 8)
            Color.white.opacity(0.04)
                .frame(height: 0.5)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Add Preset Cell

    private var addPresetCell: some View {
        Button {
            isPresented = false
            presetManager.openNewPresetEditor()
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AnimeTheme.magicalPurple.opacity(0.05))
                    .frame(height: 68)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AnimeTheme.magicalPurple.opacity(0.35),
                                        AnimeTheme.sakura.opacity(0.2),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 1.5, dash: [5, 3])
                            )
                    }
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(AnimeTheme.magicalPurple.opacity(0.45))
                    }
                Text("New")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }

    // MARK: - Preset Cell

    private func presetCell(for p: LightPreset, isCustom: Bool) -> some View {
        let isSelected = presetManager.currentPresetId == p.id
        return Button {
            HapticHelper.light.fire()
            presetManager.selectPreset(p.id)
            isPresented = false
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    // Colour swatch
                    presetSwatch(for: p)
                        .frame(height: 68)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Selection glow ring
                    if isSelected && !deleteMode {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                AngularGradient(
                                    colors: [AnimeTheme.starlight, p.color, AnimeTheme.starlight],
                                    center: .center
                                ),
                                lineWidth: 2
                            )
                            .shadow(color: p.color.opacity(0.4), radius: 6, x: 0, y: 1)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.06), lineWidth: 0.5)
                    }

                    // Delete mode overlay
                    if deleteMode && isCustom {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.red.opacity(0.2))
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.4), lineWidth: 2)
                    }

                    // Sparkle badge (top-right, selected)
                    if isSelected && !deleteMode {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "sparkle")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(AnimeTheme.starlight)
                                    .padding(5)
                                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                            }
                            Spacer()
                        }
                    }

                    // Heart badge (top-left, custom)
                    if p.isCustom && !deleteMode {
                        VStack {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 7))
                                    .foregroundColor(AnimeTheme.sakura.opacity(0.75))
                                    .padding(5)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
                .scaleEffect(isSelected && !deleteMode ? 1.03 : 1.0)

                // Name
                Text(loc.presetName(for: p))
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.65))
                    .lineLimit(1)

                // Mode label (custom presets only)
                if p.isCustom {
                    Text(modeLabel(p.mode))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
    }

    // MARK: - Swatch Rendering

    @ViewBuilder
    private func presetSwatch(for p: LightPreset) -> some View {
        switch p.mode {
        case .solid:
            Rectangle().fill(p.color)
        case .gradient:
            let (s, e) = p.splitDirection.gradientPoints
            Rectangle().fill(LinearGradient(colors: [p.color, p.secondColor], startPoint: s, endPoint: e))
        case .dual:
            switch p.splitDirection {
            case .horizontal:
                HStack(spacing: 0) {
                    Rectangle().fill(p.color)
                    Rectangle().fill(p.secondColor)
                }
            case .vertical:
                VStack(spacing: 0) {
                    Rectangle().fill(p.color)
                    Rectangle().fill(p.secondColor)
                }
            case .diagonalLeft, .diagonalRight:
                let (s, e) = p.splitDirection.gradientPoints
                Rectangle().fill(
                    LinearGradient(
                        stops: [.init(color: p.color, location: 0.48),
                                .init(color: p.secondColor, location: 0.52)],
                        startPoint: s, endPoint: e
                    )
                )
            }
        }
    }

    private func modeLabel(_ mode: PresetMode) -> String {
        switch mode {
        case .solid:    return loc.string("mode_solid")
        case .gradient: return loc.string("mode_gradient")
        case .dual:     return loc.string("mode_dual")
        }
    }

    // MARK: - Delete Overlay

    private func deleteOverlay(for p: LightPreset) -> some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    presetManager.deleteCustomPreset(p)
                    if presetManager.customPresets.isEmpty { deleteMode = false }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                }
                .padding(6)
            }
            Spacer()
        }
    }

    // MARK: - Custom Preset Actions

    private func editCustomPreset(_ p: LightPreset) {
        isPresented = false
        presetManager.openEditPreset(p)
    }

    private func deleteCustomPreset(_ p: LightPreset) {
        presetManager.deleteCustomPreset(p)
        if presetManager.customPresets.isEmpty { deleteMode = false }
    }
}
