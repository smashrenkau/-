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
            ScrollView {
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

                    // セグメント一覧
                    if !viewModel.segments.isEmpty {
                        segmentListView
                    }

                    Spacer(minLength: 16)

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
            }
            .navigationTitle("スケジュール詳細")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Segment List

    private var segmentListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("セグメント")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            VStack(spacing: 4) {
                ForEach(viewModel.segments) { segment in
                    let status = viewModel.segmentStatus(for: segment)
                    HStack {
                        Circle()
                            .fill(segment.phase == .work
                                  ? Color(hex: viewModel.colorHex)
                                  : Color(hex: schedule.restColorHex))
                            .frame(width: 10, height: 10)

                        Text("\(segment.minutes)分")
                            .font(.subheadline)

                        Text(segment.phase == .work ? "作業" : "休憩")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(viewModel.statusLabel(for: status))
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(viewModel.statusColor(for: status).opacity(0.15))
                            .foregroundStyle(viewModel.statusColor(for: status))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(
                        status == .inProgress
                            ? Color.blue.opacity(0.05)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
}
