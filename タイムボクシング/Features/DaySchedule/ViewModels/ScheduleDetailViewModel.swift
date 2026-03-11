import SwiftUI
import SwiftData

@Observable
class ScheduleDetailViewModel {
    let schedule: ScheduleItem

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

    func delete(context: ModelContext) async {
        await NotificationService.shared.cancelNotifications(for: schedule.id)
        context.delete(schedule)
        try? context.save()
    }
}
