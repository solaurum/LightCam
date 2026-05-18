import SwiftUI

struct ShutterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.1 : 0.3),
                    radius: configuration.isPressed ? 4 : 8,
                    y: configuration.isPressed ? 2 : 4)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
