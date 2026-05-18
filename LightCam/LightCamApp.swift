import SwiftUI

@main
struct LightCamApp: App {
    @StateObject private var loc = LocalizationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(loc)
                .ignoresSafeArea()
                .preferredColorScheme(.dark)
                .statusBar(hidden: true)
        }
    }
}
