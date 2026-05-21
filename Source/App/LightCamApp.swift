import SwiftUI

@main
struct LightCamApp: App {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var presetManager = PresetManager()
    @ObservedObject private var localization = LocalizationService.shared
    @State private var showOnboarding = !StorageManager.shared.hasSeenOnboarding

    init() {
        HapticManager.isEnabled = StorageManager.shared.isHapticEnabled
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                CameraView()
                    .environmentObject(cameraManager)
                    .environmentObject(presetManager)
                    .preferredColorScheme(.dark)

                if showOnboarding {
                    OnboardingView {
                        withAnimation(AppAnimation.easeInOut) {
                            showOnboarding = false
                        }
                    }
                    .transition(.opacity)
                }
            }
            .animation(AppAnimation.easeInOut, value: showOnboarding)
        }
    }
}
