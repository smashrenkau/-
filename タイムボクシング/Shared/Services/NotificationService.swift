import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func scheduleNotifications(for schedule: ScheduleItem) async {
        guard let task = schedule.task else { return }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }

        let updatedSettings = await center.notificationSettings()
        guard updatedSettings.authorizationStatus == .authorized else { return }

        await cancelNotifications(for: schedule.id)

        var notifications: [(Date, String)] = []

        if schedule.loopCount == 0 {
            notifications.append((schedule.startDateTime, "作業開始の時間です！"))
            notifications.append((schedule.endDateTime, "お疲れ様でした！"))
        } else {
            for i in 0..<schedule.loopCount {
                let cycleOffset = TimeInterval((schedule.workMinutes + schedule.breakMinutes) * i * 60)
                let cycleStart = schedule.startDateTime.addingTimeInterval(cycleOffset)
                notifications.append((cycleStart, "作業開始の時間です！"))

                let breakStart = cycleStart.addingTimeInterval(TimeInterval(schedule.workMinutes * 60))
                notifications.append((breakStart, "休憩の時間です！"))
            }
            notifications.append((schedule.endDateTime, "お疲れ様でした！"))
        }

        let scheduleIdString = schedule.id.uuidString
        for (index, (date, message)) in notifications.enumerated() {
            guard date > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = task.name
            content.body = message
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "\(scheduleIdString)_\(index)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            try? await center.add(request)
        }
    }

    func cancelNotifications(for scheduleId: UUID) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let prefix = scheduleId.uuidString
        let identifiers = pending
            .filter { $0.identifier.hasPrefix(prefix) }
            .map(\.identifier)
        if !identifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
}
