import SwiftUI
import SwiftData

@Observable
class CalendarViewModel {
    var currentDate: Date = Date()

    var currentYear: Int {
        Calendar.current.component(.year, from: currentDate)
    }

    var currentMonth: Int {
        Calendar.current.component(.month, from: currentDate)
    }

    var headerText: String {
        "\(currentYear)年\(currentMonth)月"
    }

    /// 月のカレンダー用日付配列（月曜始まり、先頭の空セルはnil）
    var daysInMonth: [Date?] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: currentDate),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))
        else { return [] }

        let weekday = calendar.component(.weekday, from: firstDay)
        // 月曜始まり: Mon=0, Tue=1, ... Sun=6
        let mondayBasedOffset = (weekday + 5) % 7

        var days: [Date?] = Array(repeating: nil, count: mondayBasedOffset)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    func dayNumber(_ date: Date) -> Int {
        Calendar.current.component(.day, from: date)
    }

    func goToPreviousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
        }
    }

    func goToNextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
        }
    }

    func schedules(for date: Date, from allSchedules: [ScheduleItem]) -> [ScheduleItem] {
        allSchedules
            .filter { Calendar.current.isDate($0.startDateTime, inSameDayAs: date) }
            .sorted { $0.startDateTime < $1.startDateTime }
    }

    var numberOfRows: Int {
        let totalCells = daysInMonth.count
        return (totalCells + 6) / 7
    }
}
