import SwiftUI

struct ColorPickerView: View {
    @EnvironmentObject var presetManager: PresetManager
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localization = LocalizationService.shared

    @State private var colorMode: ColorType = .solid
    @State private var primaryColor: Color = Color(hex: "#FF69B4")
    @State private var secondaryColor: Color = .white
    @State private var editingTarget: EditingTarget = .primary
    @State private var showRenameSheet = false

    private enum EditingTarget {
        case primary, secondary
    }

    var body: some View {
        ZStack {
            Color(hex: "#1a1a1a").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 16) {
                        largeColorPreview
                            .frame(height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.3), radius: 4)

                        modeTabs

                        if colorMode != .solid {
                            colorTargetTabs
                        }

                        ColorWheelView(
                            selectedColor: editingTarget == .primary ? $primaryColor : $secondaryColor,
                            onColorChanged: nil
                        )
                        .padding(.vertical, 8)

                        if colorMode != .solid {
                            dualColorStrip
                        }

                        bottomActions
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
        }
        .overlay {
            if showRenameSheet {
                RenamePresetSheet(
                    isPresented: $showRenameSheet,
                    onSave: { name in saveCustomPreset(name: name) }
                )
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: {
                primaryColor = Color(hex: "#FFFFFF")
                secondaryColor = .white
                editingTarget = .primary
                HapticManager.impact(.light)
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Large Color Preview

    private var largeColorPreview: some View {
        Group {
            switch colorMode {
            case .solid:
                primaryColor
            case .gradient:
                LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .split:
                HStack(spacing: 0) {
                    primaryColor
                    secondaryColor
                }
            }
        }
    }

    // MARK: - Mode Tabs

    private var modeTabs: some View {
        HStack(spacing: 0) {
            modeTab(label: localization.localized("solid"), mode: .solid)
            modeTab(label: localization.localized("gradient"), mode: .gradient)
            modeTab(label: localization.localized("split"), mode: .split)
        }
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func modeTab(label: String, mode: ColorType) -> some View {
        Button(action: {
            colorMode = mode
            editingTarget = .primary
            HapticManager.impact(.light)
        }) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(colorMode == mode ? .white : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    colorMode == mode
                        ? Color.white.opacity(0.25)
                        : .clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 9))
        }
    }

    // MARK: - Color Target Tabs

    private var colorTargetTabs: some View {
        HStack(spacing: 10) {
            colorTargetTab(
                label: localization.localized("start"),
                color: primaryColor,
                isActive: editingTarget == .primary
            ) {
                editingTarget = .primary
                HapticManager.impact(.light)
            }

            colorTargetTab(
                label: localization.localized("end"),
                color: secondaryColor,
                isActive: editingTarget == .secondary
            ) {
                editingTarget = .secondary
                HapticManager.impact(.light)
            }
        }
    }

    private func colorTargetTab(
        label: String,
        color: Color,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isActive ? .white : .white.opacity(0.5))
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(isActive ? Color.white.opacity(0.1) : .clear)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isActive ? Color.white.opacity(0.4) : Color.white.opacity(0.12),
                        lineWidth: 1.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Dual Color Strip

    private var dualColorStrip: some View {
        HStack(spacing: 0) {
            primaryColor
                .frame(maxWidth: .infinity)
            secondaryColor
                .frame(maxWidth: .infinity)
        }
        .frame(height: 6)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .shadow(color: .black.opacity(0.15), radius: 1)
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Button(action: {
                    showRenameSheet = true
                }) {
                    Label(localization.localized("save_as_preset"), systemImage: "square.and.arrow.down")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: {
                    applyOnce()
                }) {
                    Text(localization.localized("use_once"))
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
            }

            Button(action: revertToCurrent) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 11))
                    Text(localization.localized("revert_to_current"))
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Actions

    private func revertToCurrent() {
        let current = presetManager.currentPreset.color
        primaryColor = Color(current.primaryColor)
        if let sec = current.secondaryColor {
            secondaryColor = Color(sec)
        }
        colorMode = current.type
        editingTarget = .primary
        HapticManager.impact(.light)
    }

    private func saveCustomPreset(name: String) {
        let colorData = buildColorData()
        presetManager.saveCustomPreset(name: name, color: colorData)
        dismiss()
    }

    private func applyOnce() {
        let colorData = buildColorData()
        if let customIndex = presetManager.builtInPresets.firstIndex(where: { $0.id == "custom" }) {
            var customPreset = presetManager.builtInPresets[customIndex]
            customPreset.color = colorData
            customPreset.brightness = presetManager.screenBrightness
            customPreset.colorBrightness = presetManager.colorBrightness
            presetManager.applyPreset(customPreset)
        }
        dismiss()
    }

    private func buildColorData() -> ColorData {
        let primaryUIColor = UIColor(primaryColor)
        let secondaryUIColor = colorMode != .solid ? UIColor(secondaryColor) : nil

        switch colorMode {
        case .solid:
            return .solid(primaryUIColor)
        case .gradient:
            return .gradient(
                primary: primaryUIColor,
                secondary: secondaryUIColor ?? .white,
                angle: 135
            )
        case .split:
            return .split(
                primary: primaryUIColor,
                secondary: secondaryUIColor ?? .white
            )
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ColorPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ColorPickerView()
            .environmentObject(PresetManager.preview)
    }
}
#endif
