import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = TimerViewModel()
    @Query private var allSchedules: [ScheduleItem]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                phaseLabel
                timerDisplay
                progressIndicator

                Spacer()

                if viewModel.timerState == .idle {
                    idleControls
                } else {
                    activeControls
                }

                if let message = viewModel.noScheduleMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }

                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, 24)
            .navigationTitle("タイマー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.primary)
                    }
                }
                if viewModel.timerState != .idle && viewModel.timerMode == .scheduleSynced {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.toggleMute()
                        } label: {
                            Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                viewModel.onEnterBackground()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                viewModel.onEnterForeground()
            }
        }
    }

    // MARK: - Phase Label

    private var phaseLabel: some View {
        Text(viewModel.phaseLabel)
            .font(.title3.bold())
            .foregroundStyle(phaseLabelColor)
            .padding(.bottom, 16)
    }

    private var phaseLabelColor: Color {
        switch viewModel.timerPhase {
        case .work:
            if let schedule = viewModel.currentSchedule {
                return Color(hex: schedule.displayColorHex)
            }
            return .primary
        case .breakTime:
            return .green
        }
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        Text(viewModel.displayTime)
            .font(.system(size: 72, weight: .thin, design: .monospaced))
            .contentTransition(.numericText())
            .animation(.linear(duration: 0.1), value: viewModel.remainingSeconds)
            .foregroundStyle(viewModel.timerState == .paused ? .secondary : .primary)
    }

    // MARK: - Progress

    private var progressIndicator: some View {
        Group {
            if viewModel.timerState != .idle,
               let schedule = viewModel.currentSchedule,
               schedule.loopCount > 0 {
                HStack(spacing: 6) {
                    ForEach(0..<schedule.loopCount, id: \.self) { index in
                        Circle()
                            .fill(index <= viewModel.currentCycleIndex ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 16)
            }
        }
    }

    // MARK: - Idle Controls

    private var idleControls: some View {
        VStack(spacing: 24) {
            manualTimePicker

            HStack(spacing: 16) {
                Button {
                    viewModel.startManualTimer()
                } label: {
                    timerButton(label: "スタート", color: .blue)
                }

                Button {
                    viewModel.syncWithSchedule(allSchedules: allSchedules)
                } label: {
                    timerButton(label: "スケジュールと同期", color: .orange)
                }
            }
        }
    }

    private var manualTimePicker: some View {
        HStack {
            Text("タイマー時間")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Picker("分", selection: $viewModel.manualMinutes) {
                ForEach([1, 5, 10, 15, 20, 25, 30, 45, 60, 90, 120], id: \.self) { minutes in
                    Text("\(minutes)分").tag(minutes)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Active Controls

    private var activeControls: some View {
        Group {
            if viewModel.timerMode == .scheduleSynced {
                scheduleSyncedButtons
            } else {
                manualModeButtons
            }
        }
    }

    private var scheduleSyncedButtons: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.togglePause()
            } label: {
                timerButton(
                    label: viewModel.stopButtonLabel,
                    color: viewModel.timerState == .paused ? .green : .yellow
                )
            }

            Button {
                viewModel.syncWithSchedule(allSchedules: allSchedules)
            } label: {
                timerButton(label: "同期", color: .orange)
            }

            Button {
                viewModel.cancel()
            } label: {
                timerButton(label: "キャンセル", color: .red)
            }
        }
    }

    private var manualModeButtons: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.togglePause()
            } label: {
                timerButton(
                    label: viewModel.stopButtonLabel,
                    color: viewModel.timerState == .paused ? .green : .yellow
                )
            }

            Button {
                viewModel.cancel()
            } label: {
                timerButton(label: "キャンセル", color: .red)
            }
        }
    }

    // MARK: - Helper

    private func timerButton(label: String, color: Color) -> some View {
        Text(label)
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
