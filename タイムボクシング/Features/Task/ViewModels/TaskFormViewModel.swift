import SwiftUI
import SwiftData

@Observable
class TaskFormViewModel {
    var name: String = ""
    var selectedColorHex: String = "#FFB3B3"

    static let colorPalette: [(hex: String, label: String)] = [
        ("#FFB3B3", "ピンク"),
        ("#FFD9B3", "オレンジ"),
        ("#FFFFB3", "イエロー"),
        ("#B3FFB3", "グリーン"),
        ("#B3FFE0", "ミント"),
        ("#B3F0FF", "スカイブルー"),
        ("#B3C6FF", "ラベンダーブルー"),
        ("#D9B3FF", "ラベンダー"),
        ("#FFB3E0", "ローズ"),
        ("#D9D9D9", "グレー"),
    ]

    func isDuplicate(existingTasks: [TaskItem]) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        return existingTasks.contains { $0.name == trimmed }
    }

    func canSave(existingTasks: [TaskItem]) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        return !isDuplicate(existingTasks: existingTasks)
    }

    func save(context: ModelContext) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let task = TaskItem(name: trimmed, colorHex: selectedColorHex)
        context.insert(task)
        try? context.save()
    }
}
