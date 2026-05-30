import SwiftUI

struct PresetCard: View {
    @ObservedObject private var localization = LocalizationService.shared
    let preset: LightPreset
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            ColorPreviewView(colorData: preset.color)
                .frame(height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                .padding(6)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(isSelected ? 0.14 : 0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isSelected ? Color(preset.color.primaryColor).opacity(0.5) : Color.white.opacity(0.1),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                )

            Text(preset.localizedName(using: localization))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Custom Add Card

struct CustomAddCard: View {
    let title: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.white.opacity(0.6))
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Color.white.opacity(0.25),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                )

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Shared Color Preview

struct ColorPreviewView: View {
    let colorData: ColorData

    var body: some View {
        switch colorData.type {
        case .solid:
            Color(colorData.primaryColor)
        case .gradient:
            LinearGradient(
                colors: [
                    Color(colorData.primaryColor),
                    Color(colorData.secondaryColor ?? .white),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .split:
            splitPreview
        }
    }

    @ViewBuilder
    private var splitPreview: some View {
        let primary = Color(colorData.primaryColor)
        let secondary = Color(colorData.secondaryColor ?? .white)
        let direction = colorData.splitDirection ?? .horizontal

        switch direction {
        case .horizontal:
            HStack(spacing: 0) {
                primary
                secondary
            }
        case .vertical:
            VStack(spacing: 0) {
                primary
                secondary
            }
        case .diagonalLeft:
            LinearGradient(
                stops: [
                    .init(color: primary, location: 0.48),
                    .init(color: secondary, location: 0.52),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .diagonalRight:
            LinearGradient(
                stops: [
                    .init(color: primary, location: 0.48),
                    .init(color: secondary, location: 0.52),
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PresetCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(hex: "#1a1a1a").ignoresSafeArea()
            VStack(spacing: 16) {
                PresetCard(
                    preset: PresetManager.preview.builtInPresets[1],
                    isSelected: true
                )
                .frame(width: 140)

                PresetCard(
                    preset: PresetManager.preview.builtInPresets[3],
                    isSelected: false
                )
                .frame(width: 140)
            }
        }
    }
}
#endif
