import SwiftUI

struct DeleteModeSheet: View {
    @ObservedObject private var localization = LocalizationService.shared
    let preset: LightPreset
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 12) {
                ColorPreviewView(colorData: preset.color)
                    .frame(height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(preset.localizedName(using: localization))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#1a1a1a"))

                Text(localization.localized("choose_action"))
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#1a1a1a").opacity(0.6))

                HStack(spacing: 8) {
                    Button(action: {
                        isPresented = false
                        onEdit()
                    }) {
                        Label(localization.localized("edit"), systemImage: "pencil")
                            .font(.system(size: 13, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#2C2C2A"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        isPresented = false
                        onDelete()
                    }) {
                        Label(localization.localized("delete"), systemImage: "trash")
                            .font(.system(size: 13, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#FF4444"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }

                Button(action: { isPresented = false }) {
                    Text(localization.localized("cancel"))
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#E5E5E5"))
                        .foregroundColor(.gray)
                        .cornerRadius(10)
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 40)
            .shadow(color: .black.opacity(0.3), radius: 30)
            .contentShape(Rectangle())
            .onTapGesture {}
        }
    }

}
