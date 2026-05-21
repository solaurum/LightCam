import SwiftUI

/// iOS 15-compatible rename overlay (since .alert with TextField requires iOS 16)
struct RenamePresetSheet: View {
    @ObservedObject private var localization = LocalizationService.shared
    @Binding var isPresented: Bool
    let onSave: (String) -> Void

    @State private var name: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 16) {
                Text(localization.localized("rename_title"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#1a1a1a"))

                TextField(localization.localized("rename_placeholder"), text: $name)
                    .font(.system(size: 15))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isFocused)

                HStack(spacing: 10) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text(localization.localized("cancel"))
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.15))
                            .foregroundColor(.gray)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty {
                            isPresented = false
                            onSave(trimmed)
                        }
                    }) {
                        Text(localization.localized("rename_confirm"))
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(hex: "#FF69B4"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 40)
            .shadow(color: .black.opacity(0.3), radius: 30)
            .contentShape(Rectangle())
            .onTapGesture {}
        }
        .onAppear {
            isFocused = true
        }
    }
}
