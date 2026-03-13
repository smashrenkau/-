import SwiftUI
import SwiftData

@MainActor
@Observable
class ScheduleDetailViewModel {
    let schedule: ScheduleItem
    private let timerService = TimerService.shared

    init(schedule: ScheduleItem) {
        self.schedule = schedule
    }

    var taskName: String {
        schedule.displayTaskName
    }

    var colorHex: String {
        schedule.displayColorHex
    }

    var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let start = formatter.string(from: schedule.startDateTime)
        let end = formatter.string(from: schedule.endDateTime)
        return "\(start)〜\(end)"
    }

    var loopSummaryText: String? {
        guard schedule.loopCount > 0 else { return nil }
        return "（\(schedule.workMinutes)分 + \(schedule.breakMinutes)分）× \(schedule.loopCount)回"
    }

    var segments: [TimeBoxSegment] {
        schedule.timeBoxSegments
    }

    var isCurrentScheduleRunning: Bool {
        timerService.currentScheduleId == schedule.id && timerService.timerState != .idle
    }

    func segmentStatus(for segment: TimeBoxSegment) -> TimeBoxSegment.Status {
        guard timerService.currentScheduleId == schedule.id,
              timerService.timerState != .idle else {
            return .pending
        }

        let currentFlatIndex: Int
        if timerService.timerPhase == .work {
            currentFlatIndex = timerService.currentCycleIndex * 2
        } else {
            currentFlatIndex = timerService.currentCycleIndex * 2 + 1
        }

        if schedule.loopCount == 0 {
            if timerService.timerState != .idle {
                return .inProgress
            }
            return .pending
        }

        if segment.index < currentFlatIndex {
            return .completed
        } else if segment.index == currentFlatIndex {
            return .inProgress
        } else {
            return .pending
        }
    }

    func statusLabel(for status: TimeBoxSegment.Status) -> String {
        switch status {
        case .completed: return "実行済み"
        case .inProgress: return "実行中"
        case .pending: return "実行前"
        }
    }

    func statusColor(for status: TimeBoxSegment.Status) -> Color {
        switch status {
        case .completed: return .green
        case .inProgress: return .blue
        case .pending: return .gray
        }
    }

    func delete(context: ModelContext) async {
        await NotificationService.shared.cancelNotifications(for: schedule.id)
        context.delete(schedule)
        try? context.save()
    }
}
