import SwiftUI

struct CustomSlider: View {
    @Binding var value: Int
    let icon: String
    let gradient: LinearGradient

    @State private var hapticMilestones: Set<Int> = []

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 16)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(gradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )

                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.2), radius: 2)
                        .offset(x: CGFloat(value) / 100 * (geometry.size.width - 16))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    let newValue = Int(min(max(0, gesture.location.x / geometry.size.width), 1) * 100)
                                    let milestone = (newValue / 25) * 25
                                    if [25, 50, 75, 100].contains(milestone), !hapticMilestones.contains(milestone) {
                                        hapticMilestones.insert(milestone)
                                        HapticManager.impact(.light)
                                    }
                                    value = newValue
                                }
                                .onEnded { _ in
                                    hapticMilestones = []
                                }
                        )
                }
            }
            .frame(height: 22)

            Text("\(value)%")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 36, alignment: .trailing)
        }
    }
}
