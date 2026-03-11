import SwiftUI

struct TimeBoxView: View {
    let schedule: ScheduleItem

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(hex: schedule.displayColorHex))
            .overlay(alignment: .topLeading) {
                Text(schedule.displayTaskName)
                    .font(.caption.bold())
                    .foregroundStyle(.black.opacity(0.8))
                    .padding(4)
                    .lineLimit(2)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
            )
    }
}
