import SwiftUI
import SwiftData

struct ScheduleDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let schedule: ScheduleItem
    var onEdit: ((ScheduleItem) -> Void)?
    @State private var viewModel: ScheduleDetailViewModel

    init(schedule: ScheduleItem, onEdit: ((ScheduleItem) -> Void)? = nil) {
        self.schedule = schedule
        self.onEdit = onEdit
        _viewModel = State(initialValue: ScheduleDetailViewModel(schedule: schedule))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // タスク名
                HStack {
                    Circle()
                        .fill(Color(hex: viewModel.colorHex))
                        .frame(width: 16, height: 16)
                    Text(viewModel.taskName)
                        .font(.title3.bold())
                    Spacer()
                }
                .padding(.horizontal)

                // 時間範囲
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text(viewModel.timeRangeText)
                        .font(.body)
                    Spacer()
                }
                .padding(.horizontal)

                // ループ概要
                if let loopText = viewModel.loopSummaryText {
                    HStack {
                        Image(systemName: "repeat")
                            .foregroundStyle(.secondary)
                        Text(loopText)
                            .font(.body)
                        Spacer()
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // ボタン
                VStack(spacing: 12) {
                    Button {
                        dismiss()
                        onEdit?(schedule)
                    } label: {
                        Text("編集")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Button(role: .destructive) {
                        Task {
                            await viewModel.delete(context: modelContext)
                            dismiss()
                        }
                    } label: {
                        Text("削除")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding(.top, 24)
            .navigationTitle("スケジュール詳細")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
