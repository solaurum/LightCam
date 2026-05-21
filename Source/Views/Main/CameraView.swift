import SwiftUI
import AVFoundation

struct CameraView: View {
    @EnvironmentObject var cameraManager: CameraManager
    @EnvironmentObject var presetManager: PresetManager
    @Environment(\.scenePhase) var scenePhase
    @ObservedObject private var localization = LocalizationService.shared
    @StateObject private var brightnessController = BrightnessController()

    @State private var showPresetPanel = false
    @State private var showColorPicker = false
    @State private var showSettings = false
    @State private var showFlash = false
    @State private var showPreview = false
    @State private var showShareSheet = false
    @State private var isCountingDown = false
    @State private var countdownValue = 0
    @State private var timerDelay: Int = 0
    @State private var isBurstMode = false
    @State private var previewImage: UIImage?

    @State private var timer: Timer?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LightingBackgroundView()
                    .opacity(Double(presetManager.screenBrightness) / 100.0)

                ViewfinderView()

                // Settings gear
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 14)
                        .padding(.top, 48)
                    }
                    Spacer()
                }

                if showFlash {
                    Color.white
                        .ignoresSafeArea()
                        .opacity(0.85)
                        .transition(.opacity)
                }

                if isCountingDown {
                    countdownOverlay
                }

                if showPreview, let image = previewImage {
                    previewOverlay(image)
                }

                VStack(spacing: 0) {
                    Spacer()

                    slidersArea
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    shutterRow
                        .padding(.horizontal, 24)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 12)
                }
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showPresetPanel) {
            PresetPanel(
                onOpenColorPicker: {
                    showPresetPanel = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showColorPicker = true
                    }
                }
            )
            .environmentObject(presetManager)
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPickerView()
                .environmentObject(presetManager)
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = previewImage {
                ShareSheet(activityItems: [image])
            }
        }
        .overlay {
            if showSettings {
                SettingsView(onDismiss: { showSettings = false })
                    .transition(.opacity)
            }
        }
        .animation(AppAnimation.easeInOut, value: showSettings)
        .onAppear {
            brightnessController.setBrightness(Double(presetManager.screenBrightness))
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            timer?.invalidate()
            timer = nil
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                cameraManager.resumeSession()
                brightnessController.setBrightness(Double(presetManager.screenBrightness))
                UIApplication.shared.isIdleTimerDisabled = true
            case .inactive, .background:
                cameraManager.pauseSession()
                brightnessController.restore()
                UIApplication.shared.isIdleTimerDisabled = false
            @unknown default: break
            }
        }
        .onChange(of: cameraManager.capturedImage) { image in
            guard let image, !isBurstMode else { return }
            previewImage = image
            withAnimation(AppAnimation.easeInOut) {
                showPreview = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(AppAnimation.easeInOut) {
                    showPreview = false
                }
            }
        }
    }

    // MARK: - Sliders Area

    private var slidersArea: some View {
        VStack(spacing: 8) {
            CustomSlider(
                value: $presetManager.screenBrightness,
                icon: "sun.max.fill",
                gradient: LinearGradient(
                    colors: [.orange.opacity(0.6), .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .onChange(of: presetManager.screenBrightness) { val in
                brightnessController.setBrightness(Double(val))
            }

            CustomSlider(
                value: $presetManager.colorBrightness,
                icon: "paintbrush.fill",
                gradient: LinearGradient(
                    colors: [.purple.opacity(0.5), .pink, .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Shutter Row

    private var shutterRow: some View {
        HStack(spacing: 0) {
            // Left group: Preset + Timer
            HStack(spacing: 12) {
                Button(action: { showPresetPanel = true }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 44, height: 44)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(presetManager.currentPreset.color.primaryColor))
                            .frame(width: 20, height: 20)
                            .shadow(color: .black.opacity(0.2), radius: 2)
                    }
                }

                Button(action: cycleTimer) {
                    ZStack {
                        Circle()
                            .fill(timerIndicatorColor)
                            .frame(width: 44, height: 44)
                        Image(systemName: timerIcon)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                        if timerDelay > 0 {
                            Text(timerLabel)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: 14, y: -12)
                        }
                    }
                }
            }
            .frame(width: 100)
            .disabled(isCountingDown)

            Spacer()

            // Center: Shutter
            Button(action: captureAction) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 72, height: 72)
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 5)
                        .frame(width: 82, height: 82)
                }
            }
            .buttonStyle(ShutterButtonStyle())

            Spacer()

            // Right group: Mirror + Switch Camera
            HStack(spacing: 12) {
                Button(action: {
                    cameraManager.isMirrored.toggle()
                    HapticManager.impact(.light)
                }) {
                    ZStack {
                        Circle()
                            .fill(cameraManager.isMirrored ? Color.white.opacity(0.25) : Color.white.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Button(action: {
                    cameraManager.switchCamera()
                    HapticManager.impact(.light)
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .frame(width: 106)
            .disabled(isCountingDown)
        }
    }

    // MARK: - Timer Helpers

    private var timerDelayDisplay: Int {
        timerDelay
    }

    private var timerIcon: String {
        if timerDelay == -1 { return "square.stack.3d.up.fill" }
        if timerDelay > 0 { return "timer" }
        return "clock"
    }

    private var timerLabel: String {
        if timerDelay == -1 { return "3x" }
        return "\(timerDelay)s"
    }

    private var timerIndicatorColor: Color {
        if timerDelay == -1 {
            return Color(hex: "#FF69B4").opacity(0.3)
        }
        if timerDelay > 0 {
            return Color(hex: "#FF4444").opacity(0.3)
        }
        return Color.white.opacity(0.15)
    }

    // MARK: - Countdown Overlay

    private var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            Text("\(countdownValue + 1)")
                .font(.system(size: 96, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 20)
        }
    }

    // MARK: - Preview Overlay

    private func previewOverlay(_ image: UIImage) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showShareSheet = true }) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 90, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                        )
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                                .offset(x: -3, y: 3)
                        }
                        .shadow(color: .black.opacity(0.4), radius: 12)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 220)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }

    // MARK: - Actions

    private func captureAction() {
        if isCountingDown {
            cancelCountdown()
            return
        }
        if timerDelay == -1 {
            triggerBurst()
        } else if timerDelay > 0 {
            startCountdown()
        } else {
            triggerCapture()
        }
    }

    private func startCountdown() {
        countdownValue = timerDelay
        isCountingDown = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            DispatchQueue.main.async {
                if countdownValue > 0 {
                    countdownValue -= 1
                    HapticManager.impact(.heavy)
                } else {
                    t.invalidate()
                    timer = nil
                    isCountingDown = false
                    triggerCapture()
                }
            }
        }
    }

    private func cancelCountdown() {
        isCountingDown = false
        countdownValue = 0
        timerDelay = 0
        timer?.invalidate()
        timer = nil
    }

    private func triggerCapture() {
        withAnimation(AppAnimation.quick) {
            showFlash = true
        }
        HapticManager.impact(.heavy)
        playShutterSound()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(AppAnimation.quick) {
                showFlash = false
            }
        }

        cameraManager.capturePhoto()
    }

    private func triggerBurst() {
        isBurstMode = true
        withAnimation(AppAnimation.quick) {
            showFlash = true
        }
        HapticManager.impact(.heavy)
        playShutterSound()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(AppAnimation.quick) {
                showFlash = false
            }
        }

        cameraManager.captureBurst { images in
            isBurstMode = false
            guard let last = images.last else { return }
            previewImage = last
            withAnimation(AppAnimation.easeInOut) {
                showPreview = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(AppAnimation.easeInOut) {
                    showPreview = false
                }
            }
            for img in images {
                cameraManager.saveToPhotoLibrary(img)
            }
        }
    }

    private func playShutterSound() {
        AudioServicesPlaySystemSound(1108)
    }

    private func cycleTimer() {
        switch timerDelay {
        case 0:  timerDelay = 2
        case 2:  timerDelay = 5
        case 5:  timerDelay = 10
        case 10: timerDelay = -1  // burst mode
        default: timerDelay = 0
        }
        HapticManager.impact(.light)
    }
}

// MARK: - Share Sheet (UIKit bridge)

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Shutter Button Style

struct ShutterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
            .environmentObject(CameraManager())
            .environmentObject(PresetManager.preview)
            .preferredColorScheme(.dark)
    }
}
#endif
