import UIKit
import SwiftUI

final class PresetManager: ObservableObject {
    @Published var currentPreset: LightPreset
    @Published var customPresets: [LightPreset] = []
    @Published var screenBrightness: Int = 85
    @Published var colorBrightness: Int = 100

    private let storage = StorageManager.shared

    let builtInPresets: [LightPreset] = [
        LightPreset(id: "sakura",    name: "樱花微醺粉", color: .solid(.init(hex: "#F5A0B5")), brightness: 82, colorBrightness: 100, isCustom: false),
        LightPreset(id: "golden",    name: "黄金时刻奶黄", color: .gradient(primary: .init(hex: "#FFB380"), secondary: .init(hex: "#FFD1A0"), angle: 135), brightness: 88, colorBrightness: 100, isCustom: false),
        LightPreset(id: "aurora",    name: "极光紫薰衣草", color: .solid(.init(hex: "#7B4FBF")), brightness: 78, colorBrightness: 100, isCustom: false),
        LightPreset(id: "coral",     name: "珊瑚礁蜜桃", color: .solid(.init(hex: "#FF6B6B")), brightness: 85, colorBrightness: 100, isCustom: false),
        LightPreset(id: "glacier",   name: "冰川蓝冰白", color: .solid(.init(hex: "#A8D8EA")), brightness: 80, colorBrightness: 100, isCustom: false),
        LightPreset(id: "matcha",    name: "抹茶雾浅绿", color: .solid(.init(hex: "#B5C9A0")), brightness: 75, colorBrightness: 100, isCustom: false),
        LightPreset(id: "smoke",     name: "烟灰银珍珠白", color: .solid(.init(hex: "#D4CFC7")), brightness: 85, colorBrightness: 100, isCustom: false),
        LightPreset(id: "deepsea",   name: "深海夜光深蓝", color: .solid(.init(hex: "#3B7690")), brightness: 70, colorBrightness: 100, isCustom: false),
    ]

    init() {
        loadCustomPresets()
        let lastId = storage.loadLastUsedPresetId()
        let allPresets = builtInPresets + customPresets
        currentPreset = allPresets.first(where: { $0.id == lastId }) ?? builtInPresets[1]
        screenBrightness = currentPreset.brightness
        colorBrightness = currentPreset.colorBrightness
    }

    func applyPreset(_ preset: LightPreset) {
        currentPreset = preset
        screenBrightness = preset.brightness
        colorBrightness = preset.colorBrightness
        storage.saveLastUsedPresetId(preset.id)
    }

    func saveCustomPreset(name: String, color: ColorData) {
        let newPreset = LightPreset(
            id: UUID().uuidString,
            name: name,
            color: color,
            brightness: screenBrightness,
            colorBrightness: colorBrightness,
            isCustom: true
        )
        customPresets.append(newPreset)
        storage.saveCustomPresets(customPresets)
    }

    func updateCustomPreset(_ preset: LightPreset, with color: ColorData) {
        guard let index = customPresets.firstIndex(where: { $0.id == preset.id }) else { return }
        customPresets[index].color = color
        storage.saveCustomPresets(customPresets)
    }

    func deleteCustomPreset(_ preset: LightPreset) {
        customPresets.removeAll { $0.id == preset.id }
        storage.saveCustomPresets(customPresets)
    }

    private func loadCustomPresets() {
        customPresets = storage.loadCustomPresets()
    }
}

// MARK: - Localized Name for LightPreset

extension LightPreset {
    func localizedName(using localization: LocalizationService) -> String {
        isCustom ? name : localization.localized("preset_\(id)")
    }
}

// MARK: - Preview

extension PresetManager {
    static let preview: PresetManager = {
        let mgr = PresetManager()
        mgr.applyPreset(mgr.builtInPresets[1])
        return mgr
    }()
}
