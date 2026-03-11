import SwiftUI

struct FloatingAddButton: View {
    @State private var isExpanded = false
    var onAddSchedule: () -> Void
    var onAddTask: () -> Void
    var onShowTaskList: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if isExpanded {
                Button {
                    isExpanded = false
                    onAddSchedule()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.plus")
                        Text("スケジュール追加")
                    }
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(radius: 2)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))

                Button {
                    isExpanded = false
                    onAddTask()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "tag.fill")
                        Text("タスク追加")
                    }
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(radius: 2)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))

                Button {
                    isExpanded = false
                    onShowTaskList()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet")
                        Text("タスク一覧")
                    }
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.orange)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(radius: 2)
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
}
