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
