import SwiftUI
import SwiftData

struct ScheduleFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskItem.name) private var tasks: [TaskItem]
    @State private var viewModel: ScheduleFormViewModel
    @State private var showTaskForm = false
    @State private var showTaskList = false

    init(schedule: ScheduleItem? = nil, initialDate: Date? = nil) {
        _viewModel = State(initialValue: ScheduleFormViewModel(
            schedule: schedule,
            initialDate: initialDate
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                taskSelectionSection
                dateTimeSection
                loopCountSection
                durationSection
            }
            .navigationTitle(viewModel.isEditing ? "スケジュール編集" : "スケジュール追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            await viewModel.save(context: modelContext)
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .onChange(of: viewModel.startDateTime) { viewModel.recalculateEndDateTime() }
            .onChange(of: viewModel.loopCount) { viewModel.recalculateEndDateTime() }
            .onChange(of: viewModel.workMinutes) { viewModel.recalculateEndDateTime() }
            .onChange(of: viewModel.breakMinutes) { viewModel.recalculateEndDateTime() }
            .sheet(isPresented: $showTaskForm) {
                TaskFormView()
                    .presentationDetents([.medium])
            }
            .fullScreenCover(isPresented: $showTaskList) {
                TaskListView()
            }
        }
    }

    // MARK: - Task Selection

    private var taskSelectionSection: some View {
        Section {
            FlowLayout(spacing: 8) {
                Button {
                    showTaskForm = true
                } label: {
                    Text("+ タスク追加")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundStyle(.secondary)
                        .overlay(
                            Capsule()
                                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                .foregroundStyle(.secondary)
                        )
                }

                ForEach(tasks) { task in
                    TaskTagView(
                        name: task.name,
                        colorHex: task.colorHex,
                        isSelected: viewModel.selectedTask?.id == task.id
                    )
                    .onTapGesture {
                        viewModel.selectedTask = task
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            HStack {
                Text("タスク選択")
                Spacer()
                Button {
                    showTaskList = true
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.body)
                }
            }
        }
    }

    // MARK: - DateTime

    private var dateTimeSection: some View {
        Section("日時") {
            DatePicker(
                "開始日時",
                selection: $viewModel.startDateTime,
                displayedComponents: [.date, .hourAndMinute]
            )

            DatePicker(
                "終了日時",
                selection: .constant(viewModel.endDateTime),
                displayedComponents: [.date, .hourAndMinute]
            )
            .disabled(true)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Loop Count

    private var loopCountSection: some View {
        Section("休憩ループ回数") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0...5, id: \.self) { count in
                        Button("\(count)回") {
                            viewModel.loopCount = count
                        }
                        .buttonStyle(.bordered)
                        .tint(viewModel.loopCount == count ? .blue : .gray)
                    }
                }
            }
        }
    }

    // MARK: - Duration

    private var durationSection: some View {
        Section("作業・休憩時間") {
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("タスク時間")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("タスク時間", selection: $viewModel.workMinutes) {
                        ForEach(1...120, id: \.self) { minute in
                            Text("\(minute)分").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text("休憩時間")
                        .font(.caption)
                        .foregroundStyle(viewModel.isBreakDisabled ? .tertiary : .secondary)
                    Picker("休憩時間", selection: $viewModel.breakMinutes) {
                        ForEach(1...120, id: \.self) { minute in
                            Text("\(minute)分").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .disabled(viewModel.isBreakDisabled)
                    .opacity(viewModel.isBreakDisabled ? 0.4 : 1.0)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
