import SwiftUI
import SwiftData

enum TimerMode {
    case scheduleSynced
    case manual
}

enum TimerPhase {
    case work
    case breakTime
}

enum TimerState {
    case idle
    case running
    case paused
}

enum SegmentDisplayStatus {
    case pending
    case inProgress
    case completed
}

struct ScheduleSegmentDisplayInfo: Identifiable {
    let id: String
    let minutes: Int
    let isBreak: Bool
    let status: SegmentDisplayStatus
}

@MainActor
@Observable
class TimerViewModel {
    private let timerService = TimerService.shared

    // MARK: - Bindings for View

    var manualMinutes: Int {
        get { timerService.manualMinutes }
        set { timerService.manualMinutes = newValue }
    }

    var timerState: TimerState { timerService.timerState }
    var timerMode: TimerMode { timerService.timerMode }
    var timerPhase: TimerPhase { timerService.timerPhase }
    var remainingSeconds: Int { timerService.remainingSeconds }
    var currentCycleIndex: Int { timerService.currentCycleIndex }
    var isMuted: Bool { timerService.isMuted }
    var displayTime: String { timerService.displayTime }
    var phaseLabel: String { timerService.phaseLabel }
    var stopButtonLabel: String { timerService.stopButtonLabel }

    var scheduleColorHex: String { timerService.scheduleColorHex }
    var scheduleName: String { timerService.scheduleName }
    var scheduleLoopCount: Int { timerService.scheduleLoopCount }
    var currentScheduleId: UUID? { timerService.currentScheduleId }

    var hasActiveSchedule: Bool { timerService.currentScheduleId != nil }

    var totalSeconds: Int { timerService.totalSeconds }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - Double(remainingSeconds) / Double(totalSeconds)
    }

    // MARK: - Schedule Detail Display

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var scheduleTimeRangeText: String {
        guard let start = timerService.scheduleStartDateTime,
              let end = timerService.scheduleEndDateTime else { return "" }
        let s = Self.timeFormatter.string(from: start)
        let e = Self.timeFormatter.string(from: end)
        return "\(s) 〜 \(e)"
    }

    var scheduleLoopSummaryText: String? {
        guard timerService.scheduleLoopCount > 0 else { return nil }
        let work = timerService.scheduleWorkMinutes
        let brk = timerService.scheduleBreakMinutes
        let count = timerService.scheduleLoopCount
        return "作業\(work)分 × \(count)セット + 休憩\(brk)分"
    }

    var scheduleSegments: [ScheduleSegmentDisplayInfo] {
        let loopCount = timerService.scheduleLoopCount
        guard loopCount > 0 else {
            guard timerService.timerMode == .scheduleSynced else { return [] }
            let status: SegmentDisplayStatus = timerService.timerState != .idle ? .inProgress : .pending
            return [
                ScheduleSegmentDisplayInfo(
                    id: "work-0",
                    minutes: timerService.scheduleWorkMinutes,
                    isBreak: false,
                    status: status
                )
            ]
        }

        let currentActive = timerService.currentCycleIndex * 2 + (timerService.timerPhase == .breakTime ? 1 : 0)
        var segments: [ScheduleSegmentDisplayInfo] = []

        for i in 0..<loopCount {
            let workIndex = i * 2
            let breakIndex = i * 2 + 1

            let workStatus: SegmentDisplayStatus
            if workIndex < currentActive {
                workStatus = .completed
            } else if workIndex == currentActive && timerService.timerState != .idle {
                workStatus = .inProgress
            } else {
                workStatus = .pending
            }

            segments.append(ScheduleSegmentDisplayInfo(
                id: "work-\(i)",
                minutes: timerService.scheduleWorkMinutes,
                isBreak: false,
                status: workStatus
            ))

            let breakStatus: SegmentDisplayStatus
            if breakIndex < currentActive {
                breakStatus = .completed
            } else if breakIndex == currentActive && timerService.timerState != .idle {
                breakStatus = .inProgress
            } else {
                breakStatus = .pending
            }

            segments.append(ScheduleSegmentDisplayInfo(
                id: "break-\(i)",
                minutes: timerService.scheduleBreakMinutes,
                isBreak: true,
                status: breakStatus
            ))
        }

        return segments
    }

    // MARK: - Actions

    func startManualTimer() {
        timerService.startManualTimer()
    }

    func togglePause() {
        timerService.togglePause()
    }

    func cancel() {
        timerService.cancel()
    }

    func toggleMute() {
        timerService.toggleMute()
    }

    func onEnterBackground() {
        timerService.onEnterBackground()
    }

    func onEnterForeground() {
        timerService.onEnterForeground()
    }
}
