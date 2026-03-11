import SwiftUI

struct TaskTagView: View {
    let name: String
    let colorHex: String
    let isSelected: Bool

    var body: some View {
        Text(name)
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(hex: colorHex))
            .foregroundStyle(.black.opacity(0.8))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2.5)
            )
    }
}
