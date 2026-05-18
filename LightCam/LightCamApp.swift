import SwiftUI

@main
struct LightCamApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .ignoresSafeArea()
                .preferredColorScheme(.dark)
                .statusBar(hidden: true)
        }
    }
}
