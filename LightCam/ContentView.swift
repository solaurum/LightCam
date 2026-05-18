import SwiftUI
import AVFoundation
import Photos
#if targetEnvironment(simulator)
import SimulatorCameraClient
#endif

// MARK: - Camera Manager

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isSessionReady = false
    @Published var permissionDenied = false
    @Published var isFrontCamera = true

    private let photoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    private var photoCompletion: ((UIImage) -> Void)?

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    granted ? self?.setupSession() : (self?.permissionDenied = true)
                }
            }
        default:
            permissionDenied = true
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)
        currentInput = input

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async { self?.isSessionReady = true }
        }
    }

    func switchCamera() {
        guard let current = currentInput else { return }
        let newPosition: AVCaptureDevice.Position = current.device.position == .front ? .back : .front

        session.beginConfiguration()
        session.removeInput(current)

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
            isFrontCamera = newPosition == .front
        } else {
            session.addInput(current)
        }

        session.commitConfiguration()
    }

    func capture(completion: @escaping (UIImage) -> Void) {
        photoCompletion = completion
        photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }

    func stop() {
        if session.isRunning { session.stopRunning() }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }

        let fixed: UIImage
        if isFrontCamera, let cg = image.cgImage {
            fixed = UIImage(cgImage: cg, scale: image.scale, orientation: .leftMirrored)
        } else {
            fixed = image
        }

        DispatchQueue.main.async { [weak self] in
            self?.photoCompletion?(fixed)
            self?.saveToLibrary(fixed)
        }
    }

    private func saveToLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.creationRequestForAsset(from: image)
            }
        }
    }
}

// MARK: - Camera Preview

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let isFront: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.08, alpha: 1)
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer else { return }
        layer.frame = uiView.bounds
        layer.setAffineTransform(isFront ? CGAffineTransform(scaleX: -1, y: 1) : .identity)
    }
}

// MARK: - Light Preset

struct LightPreset: Identifiable {
    let id: Int
    let name: String
    let color: Color
    let uiColor: UIColor
    let temp: Int
    let defaultScreenBrightness: Double
    let defaultColorBrightness: Double

    init(id: Int, name: String, red: Double, green: Double, blue: Double, temp: Int,
         defaultScreenBrightness: Double = 0.88, defaultColorBrightness: Double = 0.0) {
        self.id = id
        self.name = name
        self.color = Color(red: red, green: green, blue: blue)
        self.uiColor = UIColor(red: red, green: green, blue: blue, alpha: 1)
        self.temp = temp
        self.defaultScreenBrightness = defaultScreenBrightness
        self.defaultColorBrightness = defaultColorBrightness
    }
}

// MARK: - Shutter Button Style

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

// MARK: - Content View

struct ContentView: View {
    @StateObject private var cam = CameraManager()

    @State private var screenBrightness: Double = 0.88
    @State private var colorBrightness: Double = 0.0
    @State private var currentPresetId = 1
    @State private var capturedImage: UIImage?
    @State private var showingPreview = false
    @State private var showingPresets = false
    @State private var showingPermissionAlert = false
    @State private var flashWhite = false
    @State private var viewfinderWidth: CGFloat = 280
    @State private var pendingPresetId: Int?
    @State private var hapticMilestones: Set<Int> = []

    private let minViewfinderWidth: CGFloat = 220
    private let maxViewfinderWidth: CGFloat = 340
    private let viewfinderAspect: CGFloat = 4 / 3

    private let presets: [LightPreset] = [
        LightPreset(id: 0, name: "纯白", red: 1.0, green: 1.0, blue: 1.0, temp: 6500, defaultScreenBrightness: 0.95),
        LightPreset(id: 1, name: "日落咖啡馆", red: 1.0, green: 0.55, blue: 0.20, temp: 3200, defaultScreenBrightness: 0.88),
        LightPreset(id: 2, name: "烛光暖调", red: 1.0, green: 0.40, blue: 0.10, temp: 2000, defaultScreenBrightness: 0.75),
        LightPreset(id: 3, name: "阴天自然", red: 0.68, green: 0.78, blue: 0.90, temp: 7500, defaultScreenBrightness: 0.85, defaultColorBrightness: 0.3),
        LightPreset(id: 4, name: "暖黄灯光", red: 1.0, green: 0.82, blue: 0.45, temp: 4000, defaultScreenBrightness: 0.88),
        LightPreset(id: 5, name: "粉红柔光", red: 1.0, green: 0.50, blue: 0.60, temp: 3500, defaultScreenBrightness: 0.82, defaultColorBrightness: 0.4),
        LightPreset(id: 6, name: "薰衣草", red: 0.78, green: 0.65, blue: 1.0, temp: 5000, defaultScreenBrightness: 0.85, defaultColorBrightness: 0.35),
        LightPreset(id: 7, name: "薄荷清冷", red: 0.65, green: 0.88, blue: 0.80, temp: 6800, defaultScreenBrightness: 0.88),
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 补光背景
                currentPreset.uiColor.swiftUIColor
                    .opacity(screenBrightness)
                    .animation(.easeInOut(duration: 0.35), value: currentPresetId)
                    .animation(.easeInOut(duration: 0.2), value: screenBrightness)

                // 颜色亮度叠加
                currentPreset.uiColor.swiftUIColor
                    .opacity(colorBrightness * 0.35)
                    .animation(.easeInOut(duration: 0.25), value: colorBrightness)

                // 闪光
                if flashWhite {
                    Color.white.ignoresSafeArea().transition(.opacity)
                }

                VStack(spacing: 0) {
                    Spacer()
                    viewfinderArea
                    Spacer()
                    bottomControls
                }
                .padding(.bottom, geometry.safeAreaInsets.bottom + 8)

                // 拍照预览
                if showingPreview, let img = capturedImage {
                    photoPreview(img)
                }
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
        .onAppear {
            #if targetEnvironment(simulator)
            SimulatorCamera.configure(host: "127.0.0.1", port: 9876)
            #else
            cam.start()
            #endif
            applyPresetValues()
            UIScreen.main.brightness = screenBrightness
        }
        .onDisappear { cam.stop() }
        .onChange(of: currentPresetId) { _ in applyPresetValues() }
        .onChange(of: screenBrightness) { UIScreen.main.brightness = $0 }
        .sheet(isPresented: $showingPresets) { presetPicker }
        .alert("摄像头权限被拒绝", isPresented: $showingPermissionAlert) {
            Button("打开设置", action: openSettings)
            Button("取消", role: .cancel) {}
        } message: {
            Text("请在系统设置中允许补光相机访问摄像头")
        }
        .onChange(of: cam.permissionDenied) { denied in
            if denied { showingPermissionAlert = true }
        }
    }

    // MARK: - Viewfinder

    private var viewfinderArea: some View {
        ZStack(alignment: .bottomTrailing) {
            #if targetEnvironment(simulator)
            SimulatorCameraPreviewView()
                .clipShape(RoundedRectangle(cornerRadius: 26))
            #else
            if cam.isSessionReady {
                CameraPreview(session: cam.session, isFront: cam.isFrontCamera)
                    .clipShape(RoundedRectangle(cornerRadius: 26))
            } else {
                RoundedRectangle(cornerRadius: 26)
                    .fill(Color(white: 0.08))
                    .overlay {
                        VStack(spacing: 14) {
                            ProgressView().tint(.white.opacity(0.5))
                            Text("正在启动摄像头...")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.35))
                        }
                    }
            }
            #endif

            resizeHandle
                .padding(.trailing, 8)
                .padding(.bottom, 8)
        }
        .frame(width: viewfinderWidth, height: viewfinderWidth * viewfinderAspect)
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 24, y: 12)
    }

    // MARK: Resize Handle

    private var resizeHandle: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.12))
                .frame(width: 32, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
            Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    let delta = -value.translation.height * 0.8
                    viewfinderWidth = min(max(viewfinderWidth + delta, minViewfinderWidth), maxViewfinderWidth)
                }
        )
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 14) {
            Text(currentPreset.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(contrastColor)

            HStack(spacing: 44) {
                // 预设
                Button { showingPresets = true } label: {
                    Circle()
                        .fill(currentPreset.uiColor.swiftUIColor)
                        .frame(width: 42, height: 42)
                        .overlay(Circle().stroke(contrastColor.opacity(0.2), lineWidth: 1.5))
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                }

                // 快门
                Button { triggerCapture() } label: {
                    ZStack {
                        Circle()
                            .stroke(contrastColor.opacity(0.3), lineWidth: 4)
                            .frame(width: 76, height: 76)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 62, height: 62)
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                            .frame(width: 76, height: 76)
                    }
                }
                .buttonStyle(ShutterButtonStyle())
                #if !targetEnvironment(simulator)
                .disabled(!cam.isSessionReady)
                #endif

                // 翻转摄像头
                Button {
                    cam.switchCamera()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                        .font(.system(size: 22))
                        .foregroundColor(contrastColor)
                        .frame(width: 42, height: 42)
                }
            }

            slidersArea
        }
        .padding(.bottom, 48)
    }

    // MARK: Sliders

    private var slidersArea: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "sun.min.fill")
                    .font(.system(size: 10))
                    .foregroundColor(contrastColor.opacity(0.4))
                    .frame(width: 14)
                sliderTrack(value: $screenBrightness, thumbColor: .white)
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 13))
                    .foregroundColor(contrastColor.opacity(0.4))
                    .frame(width: 14)
            }

            HStack(spacing: 8) {
                Image(systemName: "paintbrush.fill")
                    .font(.system(size: 10))
                    .foregroundColor(contrastColor.opacity(0.4))
                    .frame(width: 14)
                sliderTrack(value: $colorBrightness, thumbColor: currentPreset.uiColor.swiftUIColor)
                Text("\(Int(colorBrightness * 100))%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(contrastColor.opacity(0.5))
                    .frame(width: 30, alignment: .trailing)
            }
        }
        .padding(.horizontal, 40)
    }

    private func sliderTrack(value: Binding<Double>, thumbColor: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12)).frame(height: 5)
                Capsule().fill(Color.white.opacity(0.35))
                    .frame(width: geo.size.width * value.wrappedValue, height: 5)
                Circle()
                    .fill(thumbColor)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .offset(x: (geo.size.width - 24) * value.wrappedValue)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                let raw = max(0.0, min(1.0, v.location.x / geo.size.width))
                                value.wrappedValue = raw
                                let milestone = Int(raw * 100) / 25 * 25
                                if [25, 50, 75, 100].contains(milestone),
                                   !hapticMilestones.contains(milestone) {
                                    hapticMilestones.insert(milestone)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                            .onEnded { _ in hapticMilestones = [] }
                    )
            }
        }
        .frame(height: 28)
    }

    // MARK: - Preset Picker

    private var presetPicker: some View {
        ZStack {
            Color(hex: "#1a1a1a").ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("光效预设")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        showingPresets = false
                        pendingPresetId = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 48)

                Divider().background(Color.white.opacity(0.08))

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 12) {
                        ForEach(presets) { p in
                            let isSelected = (pendingPresetId ?? currentPresetId) == p.id
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                pendingPresetId = p.id
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    currentPresetId = p.id
                                    showingPresets = false
                                    pendingPresetId = nil
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(p.color)
                                        .frame(height: 70)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(isSelected ? Color.white : .clear, lineWidth: 3)
                                        )
                                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                                    Text(p.name)
                                        .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                                        .foregroundColor(.white)
                                    Text("\(p.temp)K")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Photo Preview

    private func photoPreview(_ image: UIImage) -> some View {
        GeometryReader { geo in
            Color.black.opacity(0.01).ignoresSafeArea()
                .onTapGesture { showingPreview = false }
                .overlay {
                    VStack(spacing: 14) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 180, height: 180 * 4 / 3)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        Text("已保存到相册")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                    .onTapGesture { showingPreview = false }
                    .transition(.scale.combined(with: .opacity))
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
        }
    }

    // MARK: - Actions

    private func triggerCapture() {
        #if !targetEnvironment(simulator)
        guard cam.isSessionReady else { return }
        #endif
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        withAnimation(.easeOut(duration: 0.12)) { flashWhite = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeIn(duration: 0.15)) { flashWhite = false }
        }

        #if targetEnvironment(simulator)
        // 模拟器中生成占位图代替实际拍照
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 360, height: 480))
        let placeholder = renderer.image { ctx in
            currentPreset.uiColor.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 360, height: 480))
        }
        capturedImage = placeholder
        withAnimation(.easeOut(duration: 0.25)) { showingPreview = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if showingPreview { showingPreview = false }
        }
        #else
        cam.capture { image in
            capturedImage = image
            withAnimation(.easeOut(duration: 0.25)) { showingPreview = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                if showingPreview { showingPreview = false }
            }
        }
        #endif
    }

    private func applyPresetValues() {
        screenBrightness = currentPreset.defaultScreenBrightness
        colorBrightness = currentPreset.defaultColorBrightness
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Computed

    private var currentPreset: LightPreset {
        presets.first(where: { $0.id == currentPresetId }) ?? presets[0]
    }

    private var contrastColor: Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        currentPreset.uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = (0.299 * r + 0.587 * g + 0.114 * b) * screenBrightness
        return luminance > 0.55 ? Color.black.opacity(0.55) : Color.white.opacity(0.75)
    }
}

// MARK: - Extensions

extension UIColor {
    var swiftUIColor: Color { Color(self) }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
