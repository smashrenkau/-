import SwiftUI

struct TimeBoxView: View {
    let segment: TimeBoxSegment

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(hex: segment.colorHex).opacity(segment.isBreak ? 0.4 : 1.0))
            .overlay(alignment: .topLeading) {
                Text(segment.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(.black.opacity(0.8))
                    .padding(4)
                    .lineLimit(2)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
            )
    }
}
