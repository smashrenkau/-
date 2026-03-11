import SwiftUI
import SwiftData

struct TaskFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskItem.name) private var existingTasks: [TaskItem]
    @State private var viewModel = TaskFormViewModel()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        NavigationStack {
            Form {
                Section("タスク名") {
                    TextField("タスク名を追加", text: $viewModel.name)
                        .autocorrectionDisabled()

                    if viewModel.isDuplicate(existingTasks: existingTasks) {
                        Text("同じ名前のタスクが既にあります")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("タスク色") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(TaskFormViewModel.colorPalette, id: \.hex) { color in
                            Circle()
                                .fill(Color(hex: color.hex))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            viewModel.selectedColorHex == color.hex ? Color.blue : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                                .overlay {
                                    if viewModel.selectedColorHex == color.hex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .onTapGesture {
                                    viewModel.selectedColorHex = color.hex
                                }
                                .accessibilityLabel(color.label)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("タスク追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        viewModel.save(context: modelContext)
                        dismiss()
                    }
                    .disabled(!viewModel.canSave(existingTasks: existingTasks))
                }
            }
        }
    }

}
