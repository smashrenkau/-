import SwiftUI
import SwiftData

@main
struct タイムボクシングApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [TaskItem.self, ScheduleItem.self])
    }
}
