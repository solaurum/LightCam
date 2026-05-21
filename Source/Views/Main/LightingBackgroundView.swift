import SwiftUI

struct LightingBackgroundView: View {
    @EnvironmentObject var presetManager: PresetManager

    var body: some View {
        Group {
            switch presetManager.currentPreset.color.type {
            case .solid:
                Color(presetManager.currentPreset.color.primaryColor)
                    .ignoresSafeArea()
            case .gradient:
                LinearGradient(
                    colors: [
                        Color(presetManager.currentPreset.color.primaryColor),
                        Color(presetManager.currentPreset.color.secondaryColor ?? .white),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            case .split:
                HStack(spacing: 0) {
                    Color(presetManager.currentPreset.color.primaryColor)
                    Color(presetManager.currentPreset.color.secondaryColor ?? .white)
                }
                .ignoresSafeArea()
            }
        }
        .overlay(
            Color(presetManager.currentPreset.color.primaryColor)
                .opacity(Double(presetManager.colorBrightness) / 100.0 * 0.35)
                .ignoresSafeArea()
        )
        .animation(AppAnimation.easeInOut, value: presetManager.currentPreset.id)
    }
}

// MARK: - Preview

#if DEBUG
struct LightingBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        LightingBackgroundView()
            .environmentObject(PresetManager.preview)
    }
}
#endif
