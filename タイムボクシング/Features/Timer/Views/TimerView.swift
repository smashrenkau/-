import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = TimerViewModel()

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 0) {
                topBar

                if viewModel.timerMode == .scheduleSynced {
                    scheduleInfoSection
                }

                Spacer()

                phaseLabelView

                donutTimerSection
                    .padding(.top, 16)

                progressIndicator

                Spacer()

                if viewModel.timerState == .idle {
                    idleControls
                } else if viewModel.timerMode == .manual {
                    manualModeButtons
                }

                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "#EEEEFA"),
                Color(hex: "#F8F7FD"),
                .white
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "#6B6B8D"))
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.85))
                    .clipShape(Circle())
                    .shadow(color: Color(hex: "#9B8FE9").opacity(0.1), radius: 4, y: 2)
            }

            Spacer()

            if viewModel.timerState != .idle && viewModel.timerMode == .scheduleSynced {
                Button {
                    viewModel.toggleMute()
                } label: {
                    Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "#6B6B8D"))
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.85))
                        .clipShape(Circle())
                        .shadow(color: Color(hex: "#9B8FE9").opacity(0.1), radius: 4, y: 2)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Schedule Info

    private var scheduleInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color(hex: viewModel.scheduleColorHex))
                    .frame(width: 14, height: 14)
                Text(viewModel.scheduleName)
                    .font(.subheadline.bold())
                Spacer()
            }

            if !viewModel.scheduleTimeRangeText.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.scheduleTimeRangeText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let loopText = viewModel.scheduleLoopSummaryText {
                HStack(spacing: 4) {
                    Image(systemName: "repeat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(loopText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !viewModel.scheduleSegments.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 3) {
                        ForEach(viewModel.scheduleSegments) { segment in
                            HStack {
                                Circle()
                                    .fill(segment.isBreak
                                          ? Color(hex: "#B3FFB3")
                                          : Color(hex: viewModel.scheduleColorHex))
                                    .frame(width: 8, height: 8)

                                Text("\(segment.minutes)分")
                                    .font(.caption)

                                Text(segment.isBreak ? "休憩" : "作業")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text(segmentStatusLabel(segment.status))
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(segmentStatusColor(segment.status).opacity(0.15))
                                    .foregroundStyle(segmentStatusColor(segment.status))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .frame(maxHeight: 100)
            }
        }
        .padding(12)
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color(hex: "#9B8FE9").opacity(0.08), radius: 8, y: 2)
        .padding(.top, 8)
    }

    private func segmentStatusLabel(_ status: SegmentDisplayStatus) -> String {
        switch status {
        case .pending: return "待機中"
        case .inProgress: return "進行中"
        case .completed: return "完了"
        }
    }

    private func segmentStatusColor(_ status: SegmentDisplayStatus) -> Color {
        switch status {
        case .pending: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        }
    }

    // MARK: - Phase Label

    private var phaseLabelView: some View {
        Text(viewModel.phaseLabel)
            .font(.title3.bold())
            .foregroundStyle(phaseLabelColor)
            .padding(.bottom, 4)
    }

    private var phaseLabelColor: Color {
        switch viewModel.timerPhase {
        case .work:
            if viewModel.timerMode == .scheduleSynced && !viewModel.scheduleColorHex.isEmpty {
                return Color(hex: viewModel.scheduleColorHex)
            }
            return Color(hex: "#5B5680")
        case .breakTime:
            return .green
        }
    }

    // MARK: - Donut + Hourglass + Timer

    private var donutTimerSection: some View {
        DonutProgressView(
            progress: viewModel.progress
        ) {
            VStack(spacing: 6) {
                HourglassView(progress: viewModel.progress)
                    .frame(width: 64, height: 90)

                timerDisplay
            }
        }
        .frame(width: 270, height: 270)
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        Text(viewModel.displayTime)
            .font(.system(size: 40, weight: .light, design: .monospaced))
            .contentTransition(.numericText())
            .animation(.linear(duration: 0.1), value: viewModel.remainingSeconds)
            .foregroundStyle(
                viewModel.timerState == .paused
                    ? Color(hex: "#9B8FE9").opacity(0.5)
                    : Color(hex: "#3D3A50")
            )
    }

    // MARK: - Progress Dots

    private var progressIndicator: some View {
        Group {
            if viewModel.timerState != .idle,
               viewModel.timerMode == .scheduleSynced,
               viewModel.scheduleLoopCount > 0 {
                HStack(spacing: 6) {
                    ForEach(0..<viewModel.scheduleLoopCount, id: \.self) { index in
                        Circle()
                            .fill(
                                index <= viewModel.currentCycleIndex
                                    ? Color(hex: "#9B8FE9")
                                    : Color(hex: "#D5D5F5")
                            )
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 16)
            }
        }
    }

    // MARK: - Idle Controls

    private var idleControls: some View {
        VStack(spacing: 20) {
            manualTimePicker

            Button {
                viewModel.startManualTimer()
            } label: {
                styledButton(label: "スタート", color: Color(hex: "#8B7FD9"))
            }
        }
    }

    private var manualTimePicker: some View {
        HStack {
            Text("タイマー時間")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "#6B6B8D"))

            Spacer()

            Picker("分", selection: $viewModel.manualMinutes) {
                ForEach([1, 5, 10, 15, 20, 25, 30, 45, 60, 90, 120], id: \.self) { minutes in
                    Text("\(minutes)分").tag(minutes)
                }
            }
            .pickerStyle(.menu)
            .tint(Color(hex: "#8B7FD9"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color(hex: "#9B8FE9").opacity(0.08), radius: 8, y: 2)
    }

    // MARK: - Manual Mode Buttons

    private var manualModeButtons: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.togglePause()
            } label: {
                styledButton(
                    label: viewModel.stopButtonLabel,
                    color: viewModel.timerState == .paused
                        ? Color(hex: "#6BC5A0")
                        : Color(hex: "#E8B84D")
                )
            }

            Button {
                viewModel.cancel()
            } label: {
                styledButton(label: "キャンセル", color: Color(hex: "#E07A7A"))
            }
        }
    }

    // MARK: - Styled Button

    private func styledButton(label: String, color: Color) -> some View {
        Text(label)
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: color.opacity(0.3), radius: 6, y: 3)
    }
}
