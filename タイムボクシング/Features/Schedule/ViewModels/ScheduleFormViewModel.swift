import SwiftUI
import SwiftData

@Observable
class ScheduleFormViewModel {
    var selectedTask: TaskItem?
    var startDateTime: Date
    var endDateTime: Date
    var loopCount: Int
    var workMinutes: Int
    var breakMinutes: Int

    private var editingSchedule: ScheduleItem?

    var isEditing: Bool { editingSchedule != nil }

    var canSave: Bool { selectedTask != nil }

    var isBreakDisabled: Bool { loopCount == 0 }

    init(schedule: ScheduleItem? = nil, initialDate: Date? = nil) {
        if let schedule {
            editingSchedule = schedule
            selectedTask = schedule.task
            startDateTime = schedule.startDateTime
            endDateTime = schedule.endDateTime
            loopCount = schedule.loopCount
            workMinutes = schedule.workMinutes
            breakMinutes = schedule.breakMinutes
        } else {
            let calendar = Calendar.current
            let now = Date()
            let start: Date
            if let initialDate {
                var comps = calendar.dateComponents([.year, .month, .day], from: initialDate)
                let nowComps = calendar.dateComponents([.hour, .minute], from: now)
                comps.hour = nowComps.hour
                comps.minute = nowComps.minute
                start = calendar.date(from: comps) ?? initialDate
            } else {
                start = now
            }
            startDateTime = start
            loopCount = 0
            workMinutes = 25
            breakMinutes = 5
            endDateTime = ScheduleItem.calculateEndDateTime(
                start: start, loopCount: 0, workMinutes: 25, breakMinutes: 5
            )
        }
    }

    func recalculateEndDateTime() {
        endDateTime = ScheduleItem.calculateEndDateTime(
            start: startDateTime,
            loopCount: loopCount,
            workMinutes: workMinutes,
            breakMinutes: breakMinutes
        )
    }

    func save(context: ModelContext) async {
        guard let task = selectedTask else { return }

        let schedule: ScheduleItem
        if let existing = editingSchedule {
            await NotificationService.shared.cancelNotifications(for: existing.id)
            existing.task = task
            existing.startDateTime = startDateTime
            existing.endDateTime = endDateTime
            existing.loopCount = loopCount
            existing.workMinutes = workMinutes
            existing.breakMinutes = breakMinutes
            schedule = existing
        } else {
            schedule = ScheduleItem(
                task: task,
                startDateTime: startDateTime,
                endDateTime: endDateTime,
                loopCount: loopCount,
                workMinutes: workMinutes,
                breakMinutes: breakMinutes
            )
            context.insert(schedule)
        }

        try? context.save()
        await NotificationService.shared.scheduleNotifications(for: schedule)
    }

    func deleteTask(_ task: TaskItem, context: ModelContext) async {
        for schedule in task.schedules {
            await NotificationService.shared.cancelNotifications(for: schedule.id)
        }
        context.delete(task)
        try? context.save()

        if selectedTask?.id == task.id {
            selectedTask = nil
        }
    }
}
