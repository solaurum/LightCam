import UIKit
import SwiftUI

final class PresetManager: ObservableObject {
    @Published var currentPreset: LightPreset
    @Published var customPresets: [LightPreset] = []
    @Published var screenBrightness: Int = 85
    @Published var colorBrightness: Int = 100

    private let storage = StorageManager.shared

    let builtInPresets: [LightPreset] = [
        LightPreset(id: "apple",     name: "苹果店白",   color: .solid(.init(hex: "#FFFFFF")), brightness: 100, colorBrightness: 100, isCustom: false),
        LightPreset(id: "sunset",    name: "日落咖啡馆", color: .gradient(primary: .init(hex: "#FFD9A8"), secondary: .init(hex: "#F5C4B3"), angle: 135), brightness: 85, colorBrightness: 100, isCustom: false),
        LightPreset(id: "cream",     name: "韩系奶油",   color: .solid(.init(hex: "#FFF0F5")), brightness: 75, colorBrightness: 100, isCustom: false),
        LightPreset(id: "cinema",    name: "电影感",     color: .split(primary: .init(hex: "#85B7EB"), secondary: .init(hex: "#F5C4B3")), brightness: 90, colorBrightness: 100, isCustom: false),
        LightPreset(id: "mint",      name: "清晨薄荷",   color: .solid(.init(hex: "#E8F5E9")), brightness: 70, colorBrightness: 100, isCustom: false),
        LightPreset(id: "lavender",  name: "薰衣草紫",   color: .solid(.init(hex: "#E8D5F2")), brightness: 80, colorBrightness: 100, isCustom: false),
        LightPreset(id: "blackscreen", name: "黑屏自拍", color: .solid(.init(hex: "#0A0A0A")), brightness: 15, colorBrightness: 5, isCustom: false),
        LightPreset(id: "custom",    name: "自定义",     color: .solid(.init(hex: "#FF69B4")), brightness: 80, colorBrightness: 100, isCustom: true),
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
