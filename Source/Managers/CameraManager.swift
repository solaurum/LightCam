import AVFoundation
import Photos
import UIKit

final class CameraManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isCameraReady = false
    @Published var capturedImage: UIImage?
    @Published var isFrontCamera = true
    @Published var isMirrored: Bool {
        didSet { StorageManager.shared.isMirrored = isMirrored }
    }

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var currentCameraPosition: AVCaptureDevice.Position = .front
    private var isSessionConfigured = false
    private var burstImages: [UIImage] = []
    private var burstCount = 0
    private var burstCompletion: (([UIImage]) -> Void)?

    private let storage = StorageManager.shared

    override init() {
        isMirrored = storage.isMirrored
        super.init()
        checkPermissions()
    }

    // MARK: - Permissions

    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted { self?.setupCamera() }
                }
            }
        case .denied, .restricted:
            isAuthorized = false
        @unknown default: break
        }
    }

    // MARK: - Setup

    private func setupCamera() {
        guard !isSessionConfigured else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition) else {
            session.commitConfiguration()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) { session.addInput(input) }

            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                photoOutput.maxPhotoQualityPrioritization = .quality
            }

            session.commitConfiguration()
            isSessionConfigured = true

            startRunning()
        } catch {
            session.commitConfiguration()
            print("Camera setup failed: \(error)")
        }
    }

    // MARK: - Session Lifecycle

    private func startRunning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async { self.isCameraReady = true }
        }
    }

    func pauseSession() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }

    func resumeSession() {
        guard isSessionConfigured, !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    // MARK: - Preview Layer

    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    // MARK: - Capture

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        if let connection = photoOutput.connection(with: .video) {
            connection.videoOrientation = currentVideoOrientation()
            connection.isVideoMirrored = isFrontCamera && isMirrored
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func captureBurst(completion: @escaping ([UIImage]) -> Void) {
        burstImages = []
        burstCount = 3
        burstCompletion = completion
        captureNextBurst()
    }

    private func captureNextBurst() {
        guard burstCount > 0 else {
            burstCompletion?(burstImages)
            burstCompletion = nil
            return
        }
        burstCount -= 1
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        if let connection = photoOutput.connection(with: .video) {
            connection.videoOrientation = currentVideoOrientation()
            connection.isVideoMirrored = isFrontCamera && isMirrored
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Switch Camera

    func switchCamera() {
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        currentCameraPosition = currentCameraPosition == .front ? .back : .front
        isFrontCamera = currentCameraPosition == .front

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition) else {
            session.commitConfiguration()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) { session.addInput(input) }
        } catch {
            print("Switch camera failed: \(error)")
        }
        session.commitConfiguration()
    }

    // MARK: - Helpers

    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portrait: return .portrait
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        case .portraitUpsideDown: return .portraitUpsideDown
        default: return .portrait
        }
    }
}

// MARK: - Photo Capture Delegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let imageData = photo.fileDataRepresentation(),
              var image = UIImage(data: imageData) else { return }

        if isFrontCamera && isMirrored {
            image = image.flippedHorizontally()
        }

        DispatchQueue.main.async {
            if self.burstCompletion != nil {
                self.burstImages.append(image)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.captureNextBurst()
                }
            } else {
                self.capturedImage = image
                self.saveToPhotoLibrary(image)
            }
        }
    }

    func saveToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            })
        }
    }
}

// MARK: - UIImage Flipping

extension UIImage {
    func flippedHorizontally() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        context.translateBy(x: size.width, y: 0)
        context.scaleBy(x: -1, y: 1)
        draw(in: CGRect(origin: .zero, size: size))
        let flipped = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return flipped ?? self
    }
}
