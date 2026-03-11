import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskItem.name) private var tasks: [TaskItem]
    @State private var viewModel = TaskListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if tasks.isEmpty {
                    ContentUnavailableView(
                        "タスクがありません",
                        systemImage: "tag.slash"
                    )
                } else {
                    taskList
                }
            }
            .navigationTitle("タスク一覧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !tasks.isEmpty {
                        Button(viewModel.isEditing ? "完了" : "編集") {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.isEditing.toggle()
                            }
                        }
                    }
                }
            }
        }
    }

    private var taskList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(tasks) { task in
                    HStack(spacing: 12) {
                        if viewModel.isEditing {
                            Button {
                                Task {
                                    await viewModel.deleteTask(task, context: modelContext)
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.red)
                            }
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        }

                        TaskTagView(
                            name: task.name,
                            colorHex: task.colorHex,
                            isSelected: false
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
    }
}
