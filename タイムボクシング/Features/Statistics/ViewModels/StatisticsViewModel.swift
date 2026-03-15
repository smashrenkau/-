import SwiftUI
import SwiftData

enum StatisticsPeriod: String, CaseIterable {
    case week = "1週間"
    case month = "1ヶ月"
    case threeMonths = "3ヶ月"
    case sixMonths = "6ヶ月"
    case year = "1年"
    case fiveYears = "5年"
    case all = "全期間"

    func startDate(from now: Date) -> Date? {
        let cal = Calendar.current
        switch self {
        case .week:
            return cal.date(byAdding: .day, value: -7, to: now)
        case .month:
            return cal.date(byAdding: .month, value: -1, to: now)
        case .threeMonths:
            return cal.date(byAdding: .month, value: -3, to: now)
        case .sixMonths:
            return cal.date(byAdding: .month, value: -6, to: now)
        case .year:
            return cal.date(byAdding: .year, value: -1, to: now)
        case .fiveYears:
            return cal.date(byAdding: .year, value: -5, to: now)
        case .all:
            return nil
        }
    }
}

struct DailyRating: Identifiable {
    let id: String
    let date: Date
    let averageRating: Double
}

@MainActor
@Observable
class StatisticsViewModel {
    var selectedPeriod: StatisticsPeriod = .week
    var selectedTooltipDate: Date?

    private let calendar = Calendar.current

    func dailyRatings(from schedules: [ScheduleItem]) -> [DailyRating] {
        let now = Date()
        let startDate = selectedPeriod.startDate(from: now)

        let rated = schedules.filter { schedule in
            guard let rating = schedule.rating, rating >= 1, rating <= 5 else { return false }
            if let start = startDate {
                return schedule.startDateTime >= start
            }
            return true
        }

        let grouped = Dictionary(grouping: rated) { schedule in
            calendar.startOfDay(for: schedule.startDateTime)
        }

        return grouped.map { (date, items) in
            let avg = Double(items.compactMap(\.rating).reduce(0, +)) / Double(items.count)
            let key = ISO8601DateFormatter().string(from: date)
            return DailyRating(id: key, date: date, averageRating: avg)
        }
        .sorted { $0.date < $1.date }
    }

    func todayAverageRating(from schedules: [ScheduleItem]) -> Double? {
        let todayStart = calendar.startOfDay(for: Date())
        let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart)!

        let todayRatings = schedules.compactMap { schedule -> Int? in
            guard let rating = schedule.rating,
                  rating >= 1, rating <= 5,
                  schedule.startDateTime >= todayStart,
                  schedule.startDateTime < todayEnd else { return nil }
            return rating
        }

        guard !todayRatings.isEmpty else { return nil }
        return Double(todayRatings.reduce(0, +)) / Double(todayRatings.count)
    }

}
