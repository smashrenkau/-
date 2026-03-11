import SwiftUI
import SwiftData

@Observable
class TaskListViewModel {
    var isEditing = false

    func deleteTask(_ task: TaskItem, context: ModelContext) async {
        for schedule in task.schedules {
            await NotificationService.shared.cancelNotifications(for: schedule.id)
        }
        context.delete(task)
        try? context.save()
    }
}
