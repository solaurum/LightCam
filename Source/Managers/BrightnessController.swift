import UIKit

final class BrightnessController: ObservableObject {
    @Published var currentBrightness: Double = 0.85
    private var originalBrightness: Double = UIScreen.main.brightness

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkThermalState),
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setBrightness(_ value: Double) {
        let normalized = min(value / 100.0, 1.0)
        UIScreen.main.brightness = normalized

        currentBrightness = normalized
    }

    @objc private func checkThermalState() {
        let state = ProcessInfo.processInfo.thermalState

        switch state {
        case .serious, .critical:
            setBrightness(min(currentBrightness * 100, 70))
        default:
            break
        }
    }

    func restore() {
        UIScreen.main.brightness = originalBrightness
    }
}
