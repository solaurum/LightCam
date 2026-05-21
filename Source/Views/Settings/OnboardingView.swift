import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var localization = LocalizationService.shared
    @State private var currentPage = 0
    let onDismiss: () -> Void

    private let pages: [(titleKey: String, bodyKey: String, symbol: String)] = [
        ("onboarding_title_1", "onboarding_body_1", "camera.fill"),
        ("onboarding_title_2", "onboarding_body_2", "paintpalette.fill"),
        ("onboarding_title_3", "onboarding_body_3", "circle.lefthalf.filled"),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageView(index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 340)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            completeOnboarding()
                        }
                    }) {
                        Text(currentPage < pages.count - 1
                             ? localization.localized("onboarding_next")
                             : localization.localized("onboarding_start"))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button(action: completeOnboarding) {
                        Text(localization.localized("onboarding_skip"))
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }

    private func pageView(index: Int) -> some View {
        let page = pages[index]
        return VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FF69B4").opacity(0.3), Color(hex: "#A29BFE").opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: page.symbol)
                    .font(.system(size: 52, weight: .medium))
                    .foregroundColor(.white)
            }

            VStack(spacing: 10) {
                Text(localization.localized(page.titleKey))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(localization.localized(page.bodyKey))
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 24)
    }

    private func completeOnboarding() {
        StorageManager.shared.hasSeenOnboarding = true
        onDismiss()
    }
}

// MARK: - Preview

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(onDismiss: {})
    }
}
#endif
