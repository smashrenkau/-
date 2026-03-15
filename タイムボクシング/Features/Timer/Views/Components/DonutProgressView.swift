import SwiftUI

struct DonutProgressView<Content: View>: View {
    let progress: Double
    @ViewBuilder let content: () -> Content

    private let trackColor = Color(hex: "#D5D5F5")
    private let progressColor = Color(hex: "#9B8FE9")
    private let lineWidth: CGFloat = 18

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.8), value: progress)

            content()
                .padding(lineWidth + 12)
        }
    }
}
