import Foundation
import SwiftData

struct TimeBoxSegment: Identifiable {
    let id: String
    let startTime: Date
    let endTime: Date
    let displayName: String
    let colorHex: String
    let isBreak: Bool
    let parentScheduleID: UUID
}

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

    var timeBoxSegments: [TimeBoxSegment] {
        let taskName = displayTaskName
        let colorHex = displayColorHex

        if loopCount == 0 {
            return [
                TimeBoxSegment(
                    id: "\(id)-work-0",
                    startTime: startDateTime,
                    endTime: endDateTime,
                    displayName: "\(taskName)（作業）",
                    colorHex: colorHex,
                    isBreak: false,
                    parentScheduleID: id
                )
            ]
        }

        var segments: [TimeBoxSegment] = []
        var current = startDateTime

        for i in 0..<loopCount {
            let workEnd = current.addingTimeInterval(TimeInterval(workMinutes * 60))
            segments.append(
                TimeBoxSegment(
                    id: "\(id)-work-\(i)",
                    startTime: current,
                    endTime: workEnd,
                    displayName: "\(taskName)（作業）",
                    colorHex: colorHex,
                    isBreak: false,
                    parentScheduleID: id
                )
            )
            current = workEnd

            let breakEnd = current.addingTimeInterval(TimeInterval(breakMinutes * 60))
            segments.append(
                TimeBoxSegment(
                    id: "\(id)-break-\(i)",
                    startTime: current,
                    endTime: breakEnd,
                    displayName: "\(taskName)（休憩）",
                    colorHex: colorHex,
                    isBreak: true,
                    parentScheduleID: id
                )
            )
            current = breakEnd
        }

        return segments
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
