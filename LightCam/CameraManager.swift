import UIKit
import AVFoundation
import Photos
#if targetEnvironment(simulator)
import SimulatorCameraClient
#endif

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isSessionReady = false
    @Published var permissionDenied = false
    @Published var isFrontCamera = true

    private let photoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    private var photoCompletion: ((Result<UIImage, Error>) -> Void)?

    func start() {
        #if targetEnvironment(simulator)
        SimulatorCamera.configure(host: "127.0.0.1", port: 9876)
        isSessionReady = true
        #else
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
        #endif
    }

    #if !targetEnvironment(simulator)
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
    #endif

    func capture(completion: @escaping (Result<UIImage, Error>) -> Void) {
        #if targetEnvironment(simulator)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 360, height: 480))
        let placeholder = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 360, height: 480))
        }
        completion(.success(placeholder))
        #else
        photoCompletion = completion
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        photoOutput.capturePhoto(with: settings, delegate: self)
        #endif
    }

    func stop() {
        #if !targetEnvironment(simulator)
        if session.isRunning { session.stopRunning() }
        #endif
    }
}

#if !targetEnvironment(simulator)
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.photoCompletion?(.failure(error))
                self?.photoCompletion = nil
            }
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            DispatchQueue.main.async { [weak self] in
                self?.photoCompletion?(.failure(CameraError.processingFailed))
                self?.photoCompletion = nil
            }
            return
        }

        let fixed: UIImage
        if isFrontCamera, let cg = image.cgImage {
            fixed = UIImage(cgImage: cg, scale: image.scale, orientation: .leftMirrored)
        } else {
            fixed = image
        }

        DispatchQueue.main.async { [weak self] in
            self?.photoCompletion?(.success(fixed))
            self?.photoCompletion = nil
            self?.saveToLibrary(fixed)
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
                     error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.photoCompletion?(.failure(error))
                self?.photoCompletion = nil
            }
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
#endif

enum CameraError: Error, LocalizedError {
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .processingFailed: return "Photo processing failed"
        }
    }
}
