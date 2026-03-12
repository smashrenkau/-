import SwiftUI
import SwiftData
import UserNotifications

enum TimerMode {
    case scheduleSynced
    case manual
}

enum TimerPhase {
    case work
    case breakTime
}

enum TimerState {
    case idle
    case running
    case paused
}

@Observable
class TimerViewModel {
    // MARK: - Timer State

    var timerMode: TimerMode = .manual
    var timerState: TimerState = .idle
    var timerPhase: TimerPhase = .work
    var remainingSeconds: Int = 0
    var manualMinutes: Int = 25
    var isMuted: Bool = false

    var currentSchedule: ScheduleItem?
    var currentCycleIndex: Int = 0
    var noScheduleMessage: String?

    private var timer: Timer?
    private var backgroundDate: Date?

    // MARK: - Computed Properties

    var displayTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var phaseLabel: String {
        switch timerState {
        case .idle:
            return "タイマー"
        case .running, .paused:
            switch timerPhase {
            case .work:
                return currentSchedule?.displayTaskName ?? "作業中"
            case .breakTime:
                return "休憩中"
            }
        }
    }

    var stopButtonLabel: String {
        timerState == .paused ? "再開" : "ストップ"
    }

    var hasActiveSchedule: Bool {
        currentSchedule != nil
    }

    // MARK: - Schedule Sync

    func syncWithSchedule(allSchedules: [ScheduleItem]) {
        let now = Date()
        let todayStart = Calendar.current.startOfDay(for: now)
        let todayEnd = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!

        let activeSchedules = allSchedules.filter { schedule in
            schedule.startDateTime < todayEnd && schedule.endDateTime > todayStart &&
            schedule.startDateTime <= now && schedule.endDateTime > now
        }

        guard let schedule = activeSchedules.first else {
            noScheduleMessage = "同期するスケジュールがありません"
            return
        }

        noScheduleMessage = nil
        currentSchedule = schedule
        timerMode = .scheduleSynced

        let elapsed = now.timeIntervalSince(schedule.startDateTime)
        let elapsedMinutes = Int(elapsed) / 60

        if schedule.loopCount == 0 {
            let remaining = schedule.workMinutes - elapsedMinutes
            if remaining > 0 {
                timerPhase = .work
                remainingSeconds = remaining * 60 - (Int(elapsed) % 60)
            } else {
                noScheduleMessage = "同期するスケジュールがありません"
                return
            }
        } else {
            let cycleLength = schedule.workMinutes + schedule.breakMinutes
            let currentCycle = elapsedMinutes / cycleLength
            let positionInCycle = elapsedMinutes % cycleLength

            if currentCycle >= schedule.loopCount {
                noScheduleMessage = "同期するスケジュールがありません"
                return
            }

            currentCycleIndex = currentCycle

            if positionInCycle < schedule.workMinutes {
                timerPhase = .work
                let remainingInPhase = schedule.workMinutes - positionInCycle
                remainingSeconds = remainingInPhase * 60 - (Int(elapsed) % 60)
            } else {
                timerPhase = .breakTime
                let remainingInPhase = cycleLength - positionInCycle
                remainingSeconds = remainingInPhase * 60 - (Int(elapsed) % 60)
            }
        }

        if remainingSeconds < 0 { remainingSeconds = 0 }
        startTimer()
    }

    // MARK: - Manual Mode

    func startManualTimer() {
        timerMode = .manual
        timerPhase = .work
        remainingSeconds = manualMinutes * 60
        currentSchedule = nil
        noScheduleMessage = nil
        startTimer()
    }

    // MARK: - Timer Control

    func togglePause() {
        switch timerState {
        case .running:
            pauseTimer()
        case .paused:
            resumeTimer()
        case .idle:
            break
        }
    }

    func cancel() {
        stopTimer()
        timerState = .idle
        remainingSeconds = 0
        currentSchedule = nil
        currentCycleIndex = 0
        noScheduleMessage = nil
        timerPhase = .work
    }

    // MARK: - Background Handling

    func onEnterBackground() {
        backgroundDate = Date()
    }

    func onEnterForeground() {
        guard let backgroundDate, timerState == .running else {
            self.backgroundDate = nil
            return
        }
        let elapsed = Int(Date().timeIntervalSince(backgroundDate))
        remainingSeconds = max(remainingSeconds - elapsed, 0)
        self.backgroundDate = nil

        if remainingSeconds <= 0 {
            onTimerComplete()
        }
    }

    // MARK: - Private

    private func startTimer() {
        timerState = .running
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
    }

    private func pauseTimer() {
        timerState = .paused
        timer?.invalidate()
        timer = nil
    }

    private func resumeTimer() {
        startTimer()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard timerState == .running else { return }
        remainingSeconds -= 1
        if remainingSeconds <= 0 {
            onTimerComplete()
        }
    }

    private func onTimerComplete() {
        remainingSeconds = 0

        if timerMode == .scheduleSynced, let schedule = currentSchedule {
            if timerPhase == .work && schedule.loopCount > 0 {
                let cycleLength = schedule.workMinutes + schedule.breakMinutes
                let currentCycle = currentCycleIndex

                if currentCycle < schedule.loopCount {
                    timerPhase = .breakTime
                    remainingSeconds = schedule.breakMinutes * 60
                    sendLocalNotification(title: schedule.displayTaskName, body: "休憩の時間です！")
                    return
                }
            } else if timerPhase == .breakTime && schedule.loopCount > 0 {
                currentCycleIndex += 1
                if currentCycleIndex < schedule.loopCount {
                    timerPhase = .work
                    remainingSeconds = schedule.workMinutes * 60
                    sendLocalNotification(title: schedule.displayTaskName, body: "作業開始の時間です！")
                    return
                }
            }

            sendLocalNotification(title: schedule.displayTaskName, body: "お疲れ様でした！")
        } else {
            sendLocalNotification(title: "タイマー", body: "お疲れ様でした！")
        }

        stopTimer()
        timerState = .idle
        currentSchedule = nil
        currentCycleIndex = 0
    }

    private func sendLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
