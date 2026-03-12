import SwiftUI

@Observable
class DayScheduleViewModel {
    let date: Date

    static let defaultHourHeight: CGFloat = 78
    static let minHourHeight: CGFloat = 40
    static let maxHourHeight: CGFloat = 200

    var hourHeight: CGFloat = DayScheduleViewModel.defaultHourHeight
    var lastScaleValue: CGFloat = 1.0

    init(date: Date) {
        self.date = date
    }

    func applyPinchScale(_ scale: CGFloat) {
        let newHeight = hourHeight * scale / lastScaleValue
        hourHeight = min(max(newHeight, Self.minHourHeight), Self.maxHourHeight)
        lastScaleValue = scale
    }

    func resetPinchScale() {
        lastScaleValue = 1.0
    }

    var headerText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日（E）"
        return formatter.string(from: date)
    }

    private var startOfDay: Date {
        Calendar.current.startOfDay(for: date)
    }

    private var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
    }

    func schedulesForDate(_ allSchedules: [ScheduleItem]) -> [ScheduleItem] {
        allSchedules.filter { $0.startDateTime < endOfDay && $0.endDateTime > startOfDay }
    }

    func yOffset(for schedule: ScheduleItem) -> CGFloat {
        let effectiveStart = max(schedule.startDateTime, startOfDay)
        let seconds = effectiveStart.timeIntervalSince(startOfDay)
        return CGFloat(seconds / 3600) * hourHeight
    }

    func boxHeight(for schedule: ScheduleItem) -> CGFloat {
        let effectiveStart = max(schedule.startDateTime, startOfDay)
        let effectiveEnd = min(schedule.endDateTime, endOfDay)
        let seconds = effectiveEnd.timeIntervalSince(effectiveStart)
        return max(CGFloat(seconds / 3600) * hourHeight, 24)
    }

    /// 重複するスケジュールをグループ化し、各スケジュールのカラム位置を返す
    func computeLayouts(for schedules: [ScheduleItem]) -> [(schedule: ScheduleItem, column: Int, totalColumns: Int)] {
        let sorted = schedules.sorted { $0.startDateTime < $1.startDateTime }
        var columnEnds: [Date] = []
        var assignments: [(schedule: ScheduleItem, column: Int)] = []

        for schedule in sorted {
            var assignedColumn = -1
            for (i, end) in columnEnds.enumerated() {
                if schedule.startDateTime >= end {
                    assignedColumn = i
                    columnEnds[i] = schedule.endDateTime
                    break
                }
            }
            if assignedColumn == -1 {
                assignedColumn = columnEnds.count
                columnEnds.append(schedule.endDateTime)
            }
            assignments.append((schedule: schedule, column: assignedColumn))
        }

        let totalColumns = max(columnEnds.count, 1)
        return assignments.map { ($0.schedule, $0.column, totalColumns) }
    }
}
