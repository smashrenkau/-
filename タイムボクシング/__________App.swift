import SwiftUI
import SwiftData

@main
struct タイムボクシングApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: TaskItem.self, ScheduleItem.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        TimerService.shared.configure(modelContainer: container)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    TimerService.shared.onEnterBackground()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    TimerService.shared.onEnterForeground()
                }
        }
        .modelContainer(container)
    }
}
