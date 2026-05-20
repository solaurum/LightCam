import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    var cam: CameraManager?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let cam = CameraManager()
        cam.start()
        self.cam = cam
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        cam?.stop()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        cam?.start()
    }
}

@main
struct LightCamApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var loc = LocalizationManager()

    var body: some Scene {
        WindowGroup {
            ContentView(cam: appDelegate.cam!)
                .environmentObject(loc)
                .ignoresSafeArea()
                .preferredColorScheme(.dark)
                .statusBar(hidden: true)
        }
    }
}
