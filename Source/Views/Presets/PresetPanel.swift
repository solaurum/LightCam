import SwiftUI

struct PresetPanel: View {
    @EnvironmentObject var presetManager: PresetManager
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localization = LocalizationService.shared
    let onOpenColorPicker: () -> Void

    @State private var showDeleteMode = false
    @State private var selectedCustomPreset: LightPreset?

    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        ZStack {
            Color(hex: "#1a1a1a").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Divider()
                    .background(Color.white.opacity(0.08))

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(localization.localized("built_in"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .textCase(.uppercase)
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: gridColumns, spacing: 10) {
                            ForEach(presetManager.builtInPresets) { preset in
                                PresetCard(
                                    preset: preset,
                                    isSelected: preset.id == presetManager.currentPreset.id
                                )
                                .onTapGesture {
                                    presetManager.applyPreset(preset)
                                    dismiss()
                                }
                            }
                        }

                        if !presetManager.customPresets.isEmpty {
                            Text(localization.localized("my_presets"))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                                .textCase(.uppercase)
                                .padding(.horizontal, 4)
                                .padding(.top, 8)

                            LazyVGrid(columns: gridColumns, spacing: 10) {
                                ForEach(presetManager.customPresets) { preset in
                                    PresetCard(preset: preset, isSelected: false)
                                        .onTapGesture {
                                            presetManager.applyPreset(preset)
                                            dismiss()
                                        }
                                        .onLongPressGesture(minimumDuration: 0.5) {
                                            HapticManager.impact(.heavy)
                                            selectedCustomPreset = preset
                                            showDeleteMode = true
                                        }
                                }
                            }
                        }

                        CustomAddCard(title: localization.localized("custom"))
                            .onTapGesture(perform: onOpenColorPicker)
                            .padding(.top, presetManager.customPresets.isEmpty ? 0 : 4)
                    }
                    .padding(16)
                    .padding(.bottom, 32)
                }
            }
        }
        .overlay(alignment: .center) {
            if showDeleteMode, let preset = selectedCustomPreset {
                DeleteModeSheet(
                    preset: preset,
                    onEdit: {
                        selectedCustomPreset = nil
                        onOpenColorPicker()
                    },
                    onDelete: {
                        presetManager.deleteCustomPreset(preset)
                        selectedCustomPreset = nil
                        showDeleteMode = false
                    },
                    isPresented: $showDeleteMode
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .animation(AppAnimation.spring, value: showDeleteMode)
            }
        }
    }

    private var header: some View {
        HStack {
            Text(localization.localized("presets"))
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
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
        .frame(height: 48)
    }
}

// MARK: - Preview

#if DEBUG
struct PresetPanel_Previews: PreviewProvider {
    static var previews: some View {
        PresetPanel(onOpenColorPicker: {})
            .environmentObject(PresetManager.preview)
    }
}
#endif
