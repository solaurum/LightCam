import SwiftUI

struct ViewfinderView: View {
    @EnvironmentObject var cameraManager: CameraManager
    @State private var viewfinderWidth: CGFloat = 260
    @State private var dragStartWidth: CGFloat = 260

    let minWidth: CGFloat = 200
    let maxWidth: CGFloat = 320
    let aspectRatio: CGFloat = 4 / 3

    var body: some View {
        GeometryReader { geometry in
            let height = viewfinderWidth * aspectRatio

            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "#1a1a1a"))
                    .frame(width: viewfinderWidth, height: height)
                    .shadow(color: .black.opacity(0.4), radius: 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.black.opacity(0.3), lineWidth: 4)
                    )

                cameraPreview
                    .frame(width: viewfinderWidth, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                .black.opacity(0.25),
                            ]),
                            center: .center,
                            startRadius: viewfinderWidth * 0.35,
                            endRadius: viewfinderWidth * 0.75
                        )
                    )
                    .frame(width: viewfinderWidth, height: height)
                    .allowsHitTesting(false)

                gridLines(width: viewfinderWidth, height: height)
                    .allowsHitTesting(false)

                cornerBrackets(width: viewfinderWidth, height: height)
                    .allowsHitTesting(false)

                resizeHandle
                    .padding(.trailing, 10)
                    .padding(.bottom, 10)
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.42)
        }
    }

    // MARK: - Camera Preview

    @ViewBuilder
    private var cameraPreview: some View {
        if cameraManager.isCameraReady {
            CameraPreviewView(cameraManager: cameraManager)
        } else {
            Color.black
        }
    }

    // MARK: - Grid Lines

    private func gridLines(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.5))
                .frame(height: 0.5)
                .position(x: width / 2, y: height * 1 / 3)
            Rectangle()
                .fill(Color.white.opacity(0.5))
                .frame(height: 0.5)
                .position(x: width / 2, y: height * 2 / 3)
            Rectangle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 0.5)
                .position(x: width * 1 / 3, y: height / 2)
            Rectangle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 0.5)
                .position(x: width * 2 / 3, y: height / 2)
        }
        .opacity(0.12)
    }

    // MARK: - Corner Brackets

    private func cornerBrackets(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            CornerBracket()
                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                .frame(width: 20, height: 20)
                .position(x: 16, y: 16)
            CornerBracket()
                .rotation(.degrees(90))
                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                .frame(width: 20, height: 20)
                .position(x: width - 16, y: 16)
            CornerBracket()
                .rotation(.degrees(-90))
                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                .frame(width: 20, height: 20)
                .position(x: 16, y: height - 16)
            CornerBracket()
                .rotation(.degrees(180))
                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                .frame(width: 20, height: 20)
                .position(x: width - 16, y: height - 16)
        }
    }

    // MARK: - Resize Handle

    private var resizeHandle: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )

            Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    if dragStartWidth == 0 { dragStartWidth = viewfinderWidth }
                    let delta = -value.translation.height * 0.6
                    let newWidth = min(max(dragStartWidth + delta, minWidth), maxWidth)
                    if abs(newWidth - viewfinderWidth) > 0.5 {
                        viewfinderWidth = newWidth
                    }
                }
                .onEnded { _ in
                    dragStartWidth = 0
                    HapticManager.impact(.light)
                }
        )
    }
}

// MARK: - Corner Bracket Shape

struct CornerBracket: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

// MARK: - Preview

#if DEBUG
struct ViewfinderView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.ignoresSafeArea()
            ViewfinderView()
                .environmentObject(CameraManager())
        }
    }
}
#endif
