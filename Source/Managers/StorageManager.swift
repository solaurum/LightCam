import Foundation

final class StorageManager {
    static let shared = StorageManager()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let customPresets = "customPresets"
        static let lastUsedPresetId = "lastUsedPresetId"
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let hapticEnabled = "hapticEnabled"
        static let isMirrored = "isMirrored"
    }

    private init() {}

    // MARK: - Custom Presets

    func saveCustomPresets(_ presets: [LightPreset]) {
        if let encoded = try? JSONEncoder().encode(presets) {
            defaults.set(encoded, forKey: Keys.customPresets)
        }
    }

    func loadCustomPresets() -> [LightPreset] {
        guard let data = defaults.data(forKey: Keys.customPresets),
              let presets = try? JSONDecoder().decode([LightPreset].self, from: data) else {
            return []
        }
        return presets
    }

    // MARK: - Last Used Preset

    func saveLastUsedPresetId(_ id: String) {
        defaults.set(id, forKey: Keys.lastUsedPresetId)
    }

    func loadLastUsedPresetId() -> String? {
        defaults.string(forKey: Keys.lastUsedPresetId)
    }

    // MARK: - Onboarding

    var hasSeenOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasSeenOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasSeenOnboarding) }
    }

    // MARK: - Haptic

    var isHapticEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.hapticEnabled) == nil { return true }
            return defaults.bool(forKey: Keys.hapticEnabled)
        }
        set {
            defaults.set(newValue, forKey: Keys.hapticEnabled)
            HapticManager.isEnabled = newValue
        }
    }

    // MARK: - Mirror

    var isMirrored: Bool {
        get { defaults.bool(forKey: Keys.isMirrored) }
        set { defaults.set(newValue, forKey: Keys.isMirrored) }
    }
}
