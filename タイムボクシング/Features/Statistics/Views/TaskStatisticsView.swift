import SwiftUI

struct TaskStatisticsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "hammer.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: "#9B8FE9").opacity(0.4))

            Text("タスク別統計は準備中です")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("今後のアップデートで追加予定です")
                .font(.subheadline)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
