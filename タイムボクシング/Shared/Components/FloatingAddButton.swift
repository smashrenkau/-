import SwiftUI

struct FloatingAddButton: View {
    @State private var isExpanded = false
    var onAddSchedule: () -> Void
    var onShowTimer: () -> Void
    var onShowStats: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if isExpanded {
                Button {
                    isExpanded = false
                    onAddSchedule()
                } label: {
                    fabMenuItem(icon: "calendar.badge.plus", text: "スケジュール追加", color: .blue)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))

                Button {
                    isExpanded = false
                    onShowTimer()
                } label: {
                    fabMenuItem(icon: "timer", text: "タイマー", color: Color(red: 0.6, green: 0.88, blue: 0.6))
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))

                Button {
                    isExpanded = false
                    onShowStats()
                } label: {
                    fabMenuItem(icon: "chart.bar.fill", text: "統計", color: .purple)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.title2.bold())
                    .frame(width: 56, height: 56)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            }
        }
    }

    private func fabMenuItem(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.subheadline.bold())
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(color)
        .foregroundStyle(.white)
        .clipShape(Capsule())
        .shadow(radius: 2)
    }
}
