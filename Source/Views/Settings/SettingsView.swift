import SwiftUI
import StoreKit

struct SettingsView: View {
    @ObservedObject private var localization = LocalizationService.shared
    @State private var hapticEnabled = StorageManager.shared.isHapticEnabled
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text(localization.localized("settings"))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 48)
                .overlay(alignment: .trailing) {
                    Button(action: { onDismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 10)
                }

                Divider()
                    .background(Color.white.opacity(0.08))

                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        // Language
                        languageSection

                        Divider()
                            .background(Color.white.opacity(0.06))
                            .padding(.vertical, 12)

                        // Preferences
                        preferencesSection

                        Divider()
                            .background(Color.white.opacity(0.06))
                            .padding(.vertical, 12)

                        // About
                        aboutSection
                    }
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: 340)
            .frame(maxHeight: 480)
            .background(Color(hex: "#1a1a1a"))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.4), radius: 40)
            .contentShape(Rectangle())
            .onTapGesture {}
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Language

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(localization.localized("language"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .padding(.horizontal, 16)

            VStack(spacing: 4) {
                ForEach(localization.availableLanguages, id: \.code) { lang in
                    Button(action: {
                        localization.currentLang = lang.code
                    }) {
                        HStack {
                            Text(lang.displayName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            if localization.currentLang == lang.code {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            localization.currentLang == lang.code
                                ? Color.white.opacity(0.1)
                                : Color.white.opacity(0.04)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(localization.localized("haptic_feedback"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .padding(.horizontal, 16)

            Button(action: {
                hapticEnabled.toggle()
                StorageManager.shared.isHapticEnabled = hapticEnabled
                HapticManager.impact(.light)
            }) {
                HStack {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 24)
                    Text(localization.localized("haptic_feedback"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $hapticEnabled)
                        .labelsHidden()
                        .tint(.blue)
                        .scaleEffect(0.8)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(localization.localized("about"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .padding(.horizontal, 16)

            VStack(spacing: 4) {
                HStack {
                    Text("LightCam")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Text("1.0")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 16)

            HStack(spacing: 10) {
                Button(action: rateApp) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text(localization.localized("rate_us"))
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button(action: sendFeedback) {
                    HStack(spacing: 4) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 10))
                        Text(localization.localized("feedback"))
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
    }

    // MARK: - Actions

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func sendFeedback() {
        let subject = "LightCam Feedback"
        let body = "\n\n---\nApp Version: 1.0\niOS: \(UIDevice.current.systemVersion)"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:feedback@lightcam.app?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(onDismiss: {})
            .preferredColorScheme(.dark)
    }
}
#endif
