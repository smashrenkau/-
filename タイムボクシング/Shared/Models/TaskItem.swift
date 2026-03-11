import Foundation
import SwiftData

@Model
class TaskItem {
    var id: UUID
    var name: String
    var colorHex: String
    @Relationship(deleteRule: .cascade, inverse: \ScheduleItem.task)
    var schedules: [ScheduleItem]

    init(name: String, colorHex: String) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.schedules = []
    }
}
