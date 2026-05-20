import SwiftUI
import AVFoundation
#if targetEnvironment(simulator)
import SimulatorCameraClient
#endif

/// Platform-appropriate camera preview that works on both simulator and device.
struct ViewfinderPreview: View {
    @EnvironmentObject var loc: LocalizationManager
    @ObservedObject var cam: CameraManager
    let isMirrored: Bool

    var body: some View {
        #if targetEnvironment(simulator)
        SimulatorCameraPreviewView()
            .scaleEffect(x: isMirrored ? -1 : 1, y: 1)
        #else
        if cam.isSessionReady {
            CameraPreview(session: cam.session, isMirrored: isMirrored)
        } else {
            RoundedRectangle(cornerRadius: 26)
                .fill(Color(white: 0.08))
                .overlay {
                    VStack(spacing: 14) {
                        ProgressView().tint(.white.opacity(0.5))
                        Text(loc.string("starting_camera"))
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
        }
        #endif
    }
}

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let isMirrored: Bool

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = UIColor(white: 0.08, alpha: 1)
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.setAffineTransform(isMirrored ? CGAffineTransform(scaleX: -1, y: 1) : .identity)
    }
}

private class PreviewView: UIView {
    let previewLayer = AVCaptureVideoPreviewLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}
