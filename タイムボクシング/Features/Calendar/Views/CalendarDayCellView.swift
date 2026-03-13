import SwiftUI

struct CalendarDayCellView: View {
    let day: Int
    let date: Date
    let isToday: Bool
    let schedules: [ScheduleItem]
    let cellHeight: CGFloat

    private let maxVisibleSchedules = 2

    private var weekday: Int {
        Calendar.current.component(.weekday, from: date)
    }

    private var dayTextColor: Color {
        if isToday { return .white }
        switch weekday {
        case 7: return .red    // 土曜日
        case 1: return .blue   // 日曜日
        default: return .primary
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("\(day)")
                .font(.caption2)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(dayTextColor)
                .frame(width: 22, height: 22)
                .background(isToday ? Color.blue : Color.clear)
                .clipShape(Circle())

            if !schedules.isEmpty {
                VStack(spacing: 1) {
                    ForEach(schedules.prefix(maxVisibleSchedules)) { schedule in
                        Text(schedule.displayTaskName)
                            .font(.system(size: 8))
                            .lineLimit(1)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: schedule.displayColorHex).opacity(0.35))
                            .cornerRadius(3)
                    }

                    if schedules.count > maxVisibleSchedules {
                        Text("+\(schedules.count - maxVisibleSchedules)")
                            .font(.system(size: 7))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, minHeight: cellHeight, maxHeight: cellHeight)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isToday ? Color.blue.opacity(0.06) : Color(.systemGray6).opacity(0.5))
        )
    }
}
