import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        CalendarView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TaskItem.self, ScheduleItem.self], inMemory: true)
}
