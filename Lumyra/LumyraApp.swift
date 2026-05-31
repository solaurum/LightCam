import SwiftUI

// MARK: - Preset Manager (ViewModel)

class PresetManager: ObservableObject {
    @Published var customPresets: [LightPreset] = [] { didSet { rebuildCaches() } }
    @Published var currentPresetId: Int = 1
    @Published var screenBrightness: Double = 0.88
    @Published var showingColorEditor = false
    @Published var editingPreset: LightPreset?

    let builtInPresets: [LightPreset]

    /// Cached so ~10 repeated accesses per body evaluation are O(1) instead of O(n).
    @Published var allPresets: [LightPreset] = []
    @Published var currentPreset: LightPreset!

    init() {
        builtInPresets = PresetManager.makeBuiltInPresets()
        let saved = UserDefaults.standard.loadCustomPresets()
        customPresets = saved
        allPresets = builtInPresets + saved
        if let first = builtInPresets.first {
            currentPresetId = first.id
            currentPreset = first
            screenBrightness = first.defaultScreenBrightness
        }
        // Defer brightness to the next run-loop iteration so init returns
        // instantly and the first frame renders before the screen hardware
        // transitions. This removes a synchronous IOKit call from the launch path.
        let brightness = screenBrightness
        DispatchQueue.main.async { UIScreen.main.brightness = brightness }
    }

    private func rebuildCaches() {
        allPresets = builtInPresets + customPresets
        if let match = allPresets.first(where: { $0.id == currentPresetId }) {
            currentPreset = match
        }
    }

    func selectPreset(_ id: Int) {
        guard currentPresetId != id else { return }
        currentPresetId = id
        if let match = allPresets.first(where: { $0.id == id }) {
            currentPreset = match
            screenBrightness = match.defaultScreenBrightness
            UIScreen.main.brightness = screenBrightness
        }
    }

    func setBrightness(_ value: Double) {
        screenBrightness = value
        UIScreen.main.brightness = value
    }

    func addCustomPreset(_ preset: LightPreset) {
        customPresets.append(preset)
        persistCustomPresets()
    }

    func updateCustomPreset(_ preset: LightPreset) {
        guard let idx = customPresets.firstIndex(where: { $0.id == preset.id }) else { return }
        customPresets[idx] = preset
        persistCustomPresets()
    }

    func deleteCustomPreset(_ preset: LightPreset) {
        customPresets.removeAll { $0.id == preset.id }
        if currentPresetId == preset.id, let first = builtInPresets.first {
            currentPresetId = first.id
            currentPreset = first
            screenBrightness = first.defaultScreenBrightness
            UIScreen.main.brightness = screenBrightness
        }
        persistCustomPresets()
    }

    func allocateCustomId() -> Int {
        UserDefaults.standard.allocateCustomPresetId()
    }

    func closeEditor() {
        showingColorEditor = false
        editingPreset = nil
    }

    func openNewPresetEditor() {
        editingPreset = nil
        showingColorEditor = true
    }

    func openEditPreset(_ preset: LightPreset) {
        editingPreset = preset
        showingColorEditor = true
    }

    // MARK: - Save

    /// Encapsulates the full save-or-update workflow so the colour editor
    /// doesn't need to know about ID allocation, naming conventions,
    /// or post-save side-effects.
    func savePreset(
        primary: UIColor, secondary: UIColor?,
        mode: PresetMode, splitDirection: SplitDirection,
        editing existing: LightPreset? = nil
    ) {
        let primaryColor = PresetColor(primary)
        let secondaryColor = secondary.map(PresetColor.init) ?? .clear

        if let existing = existing {
            let updated = LightPreset(
                id: existing.id,
                name: existing.name,
                primary: primaryColor,
                secondary: secondaryColor,
                mode: mode,
                splitDirection: splitDirection,
                defaultScreenBrightness: 0.88
            )
            updateCustomPreset(updated)
            selectPreset(updated.id)
        } else {
            let count = customPresets.count + 1
            let name = "Custom \(count)"
            let id = allocateCustomId()
            let preset = LightPreset(
                id: id,
                name: name,
                primary: primaryColor,
                secondary: secondaryColor,
                mode: mode,
                splitDirection: splitDirection,
                defaultScreenBrightness: 0.88,
                isCustom: true
            )
            addCustomPreset(preset)
            selectPreset(preset.id)
        }
        closeEditor()
    }

    private func persistCustomPresets() {
        UserDefaults.standard.saveCustomPresets(customPresets)
    }

    private static func makeBuiltInPresets() -> [LightPreset] {
        [
            // 01 🌸 Sakura Breeze — soft pink top → peachy-pink bottom
            LightPreset(id: 0, name: "Sakura Breeze",
                        primary: PresetColor(red: 1.000, green: 0.722, blue: 0.816),
                        secondary: PresetColor(red: 1.000, green: 0.541, blue: 0.710),
                        mode: .gradient, splitDirection: .vertical, defaultScreenBrightness: 0.86),
            // 02 🌅 Golden Hour — bright yellow top → warm orange bottom
            LightPreset(id: 1, name: "Golden Hour",
                        primary: PresetColor(red: 1.000, green: 0.851, blue: 0.400),
                        secondary: PresetColor(red: 0.961, green: 0.651, blue: 0.137),
                        mode: .gradient, splitDirection: .vertical, defaultScreenBrightness: 0.90),
            // 03 🟣 Aurora Purple — blue-violet top → warm purple bottom
            LightPreset(id: 2, name: "Aurora Purple",
                        primary: PresetColor(red: 0.690, green: 0.533, blue: 0.976),
                        secondary: PresetColor(red: 0.608, green: 0.427, blue: 0.843),
                        mode: .gradient, splitDirection: .vertical, defaultScreenBrightness: 0.76),
            // 04 🪸 Coral Reef — peachy-pink top → coral-red bottom
            LightPreset(id: 3, name: "Coral Reef",
                        primary: PresetColor(red: 1.000, green: 0.671, blue: 0.557),
                        secondary: PresetColor(red: 0.973, green: 0.486, blue: 0.416),
                        mode: .gradient, splitDirection: .vertical, defaultScreenBrightness: 0.84),
            // 05 🧊 Glacier Blue — pale cyan top → sky-blue bottom
            LightPreset(id: 4, name: "Glacier Blue",
                        primary: PresetColor(red: 0.659, green: 0.902, blue: 0.941),
                        secondary: PresetColor(red: 0.482, green: 0.831, blue: 0.918),
                        mode: .gradient, splitDirection: .vertical, defaultScreenBrightness: 0.80),
            // 06 🍵 Matcha Mist — yellow-green top → emerald-green bottom
            LightPreset(id: 5, name: "Matcha Mist",
                        primary: PresetColor(red: 0.784, green: 0.910, blue: 0.424),
                        secondary: PresetColor(red: 0.659, green: 0.847, blue: 0.306),
                        mode: .gradient, splitDirection: .vertical, defaultScreenBrightness: 0.78),
            // 07 🪨 Smoky Silver — warm white-grey top → cool grey bottom
            LightPreset(id: 6, name: "Smoky Silver",
                        primary: PresetColor(red: 0.910, green: 0.902, blue: 0.890),
                        secondary: PresetColor(red: 0.835, green: 0.827, blue: 0.816),
                        mode: .gradient, splitDirection: .vertical, defaultScreenBrightness: 0.88),
            // 08 🌊 Deep Sea Glow — dark teal top → deep blue-green bottom
            LightPreset(id: 7, name: "Deep Sea Glow",
                        primary: PresetColor(red: 0.102, green: 0.420, blue: 0.486),
                        secondary: PresetColor(red: 0.051, green: 0.310, blue: 0.361),
                        mode: .gradient, splitDirection: .vertical, defaultScreenBrightness: 0.70),
        ]
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    var cam: CameraManager?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let cam = CameraManager()
        self.cam = cam
        // Defer camera start to the next run-loop iteration so the first frame
        // renders before the expensive AVCaptureSession configuration kicks in.
        // This dramatically improves perceived launch time — the UI appears
        // instantly with a spinner, then the camera feeds in.
        DispatchQueue.main.async { cam.start() }
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        cam?.stop()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Same deferral as launch — let the UI breathe before reconfiguring the session.
        DispatchQueue.main.async { [weak self] in self?.cam?.start() }
    }
}

@main
struct LumyraApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var loc = LocalizationManager()
    @StateObject private var presetManager = PresetManager()

    var body: some Scene {
        WindowGroup {
            ContentView(cam: appDelegate.cam!)
                .environmentObject(loc)
                .environmentObject(presetManager)
                .ignoresSafeArea()
                .preferredColorScheme(.dark)
                .statusBar(hidden: true)
        }
    }
}
