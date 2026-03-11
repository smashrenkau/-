import Foundation
import SwiftData

@Model
class ScheduleItem {
    var id: UUID
    var task: TaskItem?
    var startDateTime: Date
    var endDateTime: Date
    var loopCount: Int
    var workMinutes: Int
    var breakMinutes: Int

    init(
        task: TaskItem? = nil,
        startDateTime: Date,
        endDateTime: Date,
        loopCount: Int = 0,
        workMinutes: Int = 25,
        breakMinutes: Int = 5
    ) {
        self.id = UUID()
        self.task = task
        self.startDateTime = startDateTime
        self.endDateTime = endDateTime
        self.loopCount = loopCount
        self.workMinutes = workMinutes
        self.breakMinutes = breakMinutes
    }

    var displayTaskName: String {
        task?.name ?? "タスクなし"
    }

    var displayColorHex: String {
        task?.colorHex ?? "#D9D9D9"
    }

    static func calculateEndDateTime(
        start: Date,
        loopCount: Int,
        workMinutes: Int,
        breakMinutes: Int
    ) -> Date {
        let totalMinutes: Int
        if loopCount == 0 {
            totalMinutes = workMinutes
        } else {
            totalMinutes = (workMinutes + breakMinutes) * loopCount
        }
        return start.addingTimeInterval(TimeInterval(totalMinutes * 60))
    }
}
