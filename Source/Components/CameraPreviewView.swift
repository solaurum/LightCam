import SwiftUI
import AVFoundation

// MARK: - UIView subclass that keeps preview layer in sync with bounds

final class CameraPreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer? {
        didSet {
            oldValue?.removeFromSuperlayer()
            if let layer = previewLayer {
                layer.frame = bounds
                self.layer.addSublayer(layer)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

// MARK: - UIViewRepresentable

struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView(frame: .zero)
        view.backgroundColor = .black
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.previewLayer = cameraManager.getPreviewLayer()
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}
