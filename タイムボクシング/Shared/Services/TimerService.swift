import SwiftUI
import SwiftData
import UserNotifications

@MainActor
@Observable
final class TimerService {
    static let shared = TimerService()

    // MARK: - Public State

    var timerState: TimerState = .idle
    var timerMode: TimerMode = .manual
    var timerPhase: TimerPhase = .work
    var remainingSeconds: Int = 0
    var currentCycleIndex: Int = 0
    var isMuted: Bool = false
    var shouldShowTimer: Bool = false
    var manualMinutes: Int = 25

    private(set) var currentScheduleId: UUID?
    private(set) var scheduleName: String = ""
    private(set) var scheduleColorHex: String = "#D9D9D9"
    private(set) var scheduleLoopCount: Int = 0
    private(set) var scheduleWorkMinutes: Int = 25
    private(set) var scheduleBreakMinutes: Int = 5
    private(set) var scheduleStartDateTime: Date?
    private(set) var scheduleEndDateTime: Date?

    // MARK: - Private

    private var timer: Timer?
    private var monitoringTimer: Timer?
    private var segmentStartDate: Date?
    private var backgroundDate: Date?
    private let audioService = AudioService.shared
    private var modelContainer: ModelContainer?

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
                return scheduleName.isEmpty ? "作業中" : scheduleName
            case .breakTime:
                return "休憩中"
            }
        }
    }

    var stopButtonLabel: String {
        timerState == .paused ? "再開" : "ストップ"
    }

    private init() {}

    // MARK: - Configuration

    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        restoreState()
        startMonitoring()
    }

    // MARK: - Schedule Monitoring (10秒ごと)

    func startMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkSchedules()
            }
        }
        checkSchedules()
    }

    private func checkSchedules() {
        guard timerState == .idle, let modelContainer else { return }

        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<ScheduleItem>()
        guard let schedules = try? context.fetch(descriptor) else { return }

        let now = Date()
        let active = schedules.first { schedule in
            schedule.startDateTime <= now && schedule.endDateTime > now
        }

        guard let schedule = active else { return }

        startScheduleTimer(
            scheduleId: schedule.id,
            taskName: schedule.displayTaskName,
            colorHex: schedule.displayColorHex,
            startDateTime: schedule.startDateTime,
            endDateTime: schedule.endDateTime,
            loopCount: schedule.loopCount,
            workMinutes: schedule.workMinutes,
            breakMinutes: schedule.breakMinutes
        )
        shouldShowTimer = true
    }

    // MARK: - Schedule Timer Start

    func startScheduleTimer(
        scheduleId: UUID,
        taskName: String,
        colorHex: String,
        startDateTime: Date,
        endDateTime: Date,
        loopCount: Int,
        workMinutes: Int,
        breakMinutes: Int
    ) {
        if timerState == .running || timerState == .paused {
            stopTimerInternal()
        }

        currentScheduleId = scheduleId
        scheduleName = taskName
        scheduleColorHex = colorHex
        scheduleStartDateTime = startDateTime
        scheduleEndDateTime = endDateTime
        scheduleLoopCount = loopCount
        scheduleWorkMinutes = workMinutes
        scheduleBreakMinutes = breakMinutes
        timerMode = .scheduleSynced

        let now = Date()
        let elapsed = now.timeIntervalSince(startDateTime)
        let elapsedSeconds = Int(elapsed)

        if loopCount == 0 {
            let totalSeconds = workMinutes * 60
            let remaining = totalSeconds - elapsedSeconds
            if remaining > 0 {
                timerPhase = .work
                remainingSeconds = remaining
                currentCycleIndex = 0
            } else {
                clearScheduleState()
                return
            }
        } else {
            let cycleSeconds = (workMinutes + breakMinutes) * 60
            let totalSeconds = cycleSeconds * loopCount

            if elapsedSeconds >= totalSeconds {
                clearScheduleState()
                return
            }

            let currentCycle = elapsedSeconds / cycleSeconds
            let positionInCycle = elapsedSeconds % cycleSeconds
            let workSeconds = workMinutes * 60

            currentCycleIndex = currentCycle

            if positionInCycle < workSeconds {
                timerPhase = .work
                remainingSeconds = workSeconds - positionInCycle
            } else {
                timerPhase = .breakTime
                remainingSeconds = cycleSeconds - positionInCycle
            }
        }

        if remainingSeconds <= 0 { remainingSeconds = 0 }
        segmentStartDate = Date()
        startTimerInternal()
        updateAudioForPhase()
        persistState()
    }

    // MARK: - Manual Timer

    func startManualTimer() {
        if timerState == .running || timerState == .paused {
            stopTimerInternal()
        }

        timerMode = .manual
        timerPhase = .work
        remainingSeconds = manualMinutes * 60
        currentScheduleId = nil
        scheduleName = ""
        scheduleColorHex = "#D9D9D9"
        audioService.stop()
        segmentStartDate = Date()
        startTimerInternal()
        persistState()
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
        stopTimerInternal()
        audioService.stop()
        clearScheduleState()
        clearPersistedState()
    }

    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            audioService.pause()
        } else if timerState == .running && timerMode == .scheduleSynced {
            updateAudioForPhase()
        }
    }

    // MARK: - Background Handling

    func onEnterBackground() {
        backgroundDate = Date()
        persistState()

        if timerMode == .scheduleSynced && timerState == .running {
            scheduleBackgroundNotifications()
        }
    }

    func onEnterForeground() {
        guard timerState == .running else {
            backgroundDate = nil
            if timerState == .idle {
                checkSchedules()
            }
            return
        }

        if timerMode == .scheduleSynced, let startDT = scheduleStartDateTime {
            recalculateFromScheduleTime(startDateTime: startDT)
        } else if let backgroundDate {
            let elapsed = Int(Date().timeIntervalSince(backgroundDate))
            remainingSeconds = max(remainingSeconds - elapsed, 0)
        }

        backgroundDate = nil

        if remainingSeconds <= 0 {
            onTimerComplete()
        } else {
            updateAudioForPhase()
        }
    }

    private func recalculateFromScheduleTime(startDateTime: Date) {
        let now = Date()
        let elapsed = now.timeIntervalSince(startDateTime)
        let elapsedSeconds = Int(elapsed)

        if scheduleLoopCount == 0 {
            let totalSeconds = scheduleWorkMinutes * 60
            let remaining = totalSeconds - elapsedSeconds
            if remaining > 0 {
                timerPhase = .work
                remainingSeconds = remaining
            } else {
                onTimerComplete()
                return
            }
        } else {
            let cycleSeconds = (scheduleWorkMinutes + scheduleBreakMinutes) * 60
            let totalSeconds = cycleSeconds * scheduleLoopCount

            if elapsedSeconds >= totalSeconds {
                onTimerComplete()
                return
            }

            let currentCycle = elapsedSeconds / cycleSeconds
            let positionInCycle = elapsedSeconds % cycleSeconds
            let workSeconds = scheduleWorkMinutes * 60

            currentCycleIndex = currentCycle

            if positionInCycle < workSeconds {
                timerPhase = .work
                remainingSeconds = workSeconds - positionInCycle
            } else {
                timerPhase = .breakTime
                remainingSeconds = cycleSeconds - positionInCycle
            }
        }
    }

    // MARK: - Private Timer Methods

    private func startTimerInternal() {
        timerState = .running
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func pauseTimer() {
        timerState = .paused
        timer?.invalidate()
        timer = nil
        if timerMode == .scheduleSynced {
            audioService.pause()
        }
        persistState()
    }

    private func resumeTimer() {
        segmentStartDate = Date()
        startTimerInternal()
        if timerMode == .scheduleSynced && !isMuted {
            audioService.resume()
        }
        persistState()
    }

    private func stopTimerInternal() {
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

        if timerMode == .scheduleSynced {
            if timerPhase == .work && scheduleLoopCount > 0 {
                if currentCycleIndex < scheduleLoopCount {
                    timerPhase = .breakTime
                    remainingSeconds = scheduleBreakMinutes * 60
                    segmentStartDate = Date()
                    sendLocalNotification(title: scheduleName, body: "休憩の時間です！")
                    updateAudioForPhase()
                    persistState()
                    return
                }
            } else if timerPhase == .breakTime && scheduleLoopCount > 0 {
                currentCycleIndex += 1
                if currentCycleIndex < scheduleLoopCount {
                    timerPhase = .work
                    remainingSeconds = scheduleWorkMinutes * 60
                    segmentStartDate = Date()
                    sendLocalNotification(title: scheduleName, body: "作業開始の時間です！")
                    updateAudioForPhase()
                    persistState()
                    return
                }
            }

            sendLocalNotification(title: scheduleName, body: "お疲れ様でした！")
        } else {
            sendLocalNotification(title: "タイマー", body: "お疲れ様でした！")
        }

        stopTimerInternal()
        audioService.stop()
        clearScheduleState()
        clearPersistedState()
    }

    private func clearScheduleState() {
        timerState = .idle
        remainingSeconds = 0
        currentScheduleId = nil
        scheduleName = ""
        scheduleColorHex = "#D9D9D9"
        scheduleStartDateTime = nil
        scheduleEndDateTime = nil
        scheduleLoopCount = 0
        currentCycleIndex = 0
        timerPhase = .work
        segmentStartDate = nil
    }

    private func updateAudioForPhase() {
        guard timerMode == .scheduleSynced, !isMuted else {
            audioService.stop()
            return
        }
        switch timerPhase {
        case .work:
            audioService.playTaskMusic()
        case .breakTime:
            audioService.playBreakMusic()
        }
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

    private func scheduleBackgroundNotifications() {
        guard let startDT = scheduleStartDateTime else { return }

        var upcomingDates: [(Date, String)] = []
        let now = Date()

        if scheduleLoopCount == 0 {
            let endDate = startDT.addingTimeInterval(TimeInterval(scheduleWorkMinutes * 60))
            if endDate > now {
                upcomingDates.append((endDate, "お疲れ様でした！"))
            }
        } else {
            for i in 0..<scheduleLoopCount {
                let cycleOffset = TimeInterval((scheduleWorkMinutes + scheduleBreakMinutes) * i * 60)
                let workStart = startDT.addingTimeInterval(cycleOffset)
                let breakStart = workStart.addingTimeInterval(TimeInterval(scheduleWorkMinutes * 60))

                if workStart > now {
                    upcomingDates.append((workStart, "作業開始の時間です！"))
                }
                if breakStart > now {
                    upcomingDates.append((breakStart, "休憩の時間です！"))
                }
            }
            if let endDT = scheduleEndDateTime, endDT > now {
                upcomingDates.append((endDT, "お疲れ様でした！"))
            }
        }

        let center = UNUserNotificationCenter.current()
        for (index, (date, message)) in upcomingDates.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = scheduleName
            content.body = message
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(date.timeIntervalSince(now), 1),
                repeats: false
            )
            let identifier = "timer_bg_\(index)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request)
        }
    }

    // MARK: - Persistence (UserDefaults)

    private func persistState() {
        guard timerState != .idle else {
            clearPersistedState()
            return
        }

        let defaults = UserDefaults.standard
        defaults.set(timerState == .running ? "running" : "paused", forKey: "ts_timerState")
        defaults.set(timerMode == .scheduleSynced ? "schedule" : "manual", forKey: "ts_timerMode")
        defaults.set(timerPhase == .work ? "work" : "break", forKey: "ts_timerPhase")
        defaults.set(remainingSeconds, forKey: "ts_remainingSeconds")
        defaults.set(currentCycleIndex, forKey: "ts_currentCycleIndex")
        defaults.set(isMuted, forKey: "ts_isMuted")
        defaults.set(segmentStartDate, forKey: "ts_segmentStartDate")
        defaults.set(currentScheduleId?.uuidString, forKey: "ts_currentScheduleId")
        defaults.set(scheduleName, forKey: "ts_scheduleName")
        defaults.set(scheduleColorHex, forKey: "ts_scheduleColorHex")
        defaults.set(scheduleLoopCount, forKey: "ts_scheduleLoopCount")
        defaults.set(scheduleWorkMinutes, forKey: "ts_scheduleWorkMinutes")
        defaults.set(scheduleBreakMinutes, forKey: "ts_scheduleBreakMinutes")
        defaults.set(scheduleStartDateTime, forKey: "ts_scheduleStartDateTime")
        defaults.set(scheduleEndDateTime, forKey: "ts_scheduleEndDateTime")
        defaults.set(manualMinutes, forKey: "ts_manualMinutes")
    }

    private func clearPersistedState() {
        let defaults = UserDefaults.standard
        let keys = [
            "ts_timerState", "ts_timerMode", "ts_timerPhase", "ts_remainingSeconds",
            "ts_currentCycleIndex", "ts_isMuted", "ts_segmentStartDate",
            "ts_currentScheduleId", "ts_scheduleName", "ts_scheduleColorHex",
            "ts_scheduleLoopCount", "ts_scheduleWorkMinutes", "ts_scheduleBreakMinutes",
            "ts_scheduleStartDateTime", "ts_scheduleEndDateTime", "ts_manualMinutes"
        ]
        keys.forEach { defaults.removeObject(forKey: $0) }
    }

    private func restoreState() {
        let defaults = UserDefaults.standard
        guard let stateStr = defaults.string(forKey: "ts_timerState") else { return }

        let modeStr = defaults.string(forKey: "ts_timerMode") ?? "manual"
        let phaseStr = defaults.string(forKey: "ts_timerPhase") ?? "work"

        timerMode = modeStr == "schedule" ? .scheduleSynced : .manual
        timerPhase = phaseStr == "work" ? .work : .breakTime
        currentCycleIndex = defaults.integer(forKey: "ts_currentCycleIndex")
        isMuted = defaults.bool(forKey: "ts_isMuted")
        scheduleName = defaults.string(forKey: "ts_scheduleName") ?? ""
        scheduleColorHex = defaults.string(forKey: "ts_scheduleColorHex") ?? "#D9D9D9"
        scheduleLoopCount = defaults.integer(forKey: "ts_scheduleLoopCount")
        scheduleWorkMinutes = defaults.integer(forKey: "ts_scheduleWorkMinutes")
        scheduleBreakMinutes = defaults.integer(forKey: "ts_scheduleBreakMinutes")
        scheduleStartDateTime = defaults.object(forKey: "ts_scheduleStartDateTime") as? Date
        scheduleEndDateTime = defaults.object(forKey: "ts_scheduleEndDateTime") as? Date
        manualMinutes = defaults.integer(forKey: "ts_manualMinutes")
        if manualMinutes == 0 { manualMinutes = 25 }

        if let idStr = defaults.string(forKey: "ts_currentScheduleId") {
            currentScheduleId = UUID(uuidString: idStr)
        }

        if timerMode == .scheduleSynced, let startDT = scheduleStartDateTime {
            let now = Date()
            if let endDT = scheduleEndDateTime, now >= endDT {
                clearPersistedState()
                return
            }
            recalculateFromScheduleTime(startDateTime: startDT)
            if remainingSeconds > 0 {
                segmentStartDate = Date()
                startTimerInternal()
                if stateStr == "paused" {
                    pauseTimer()
                } else {
                    updateAudioForPhase()
                }
            } else {
                clearScheduleState()
                clearPersistedState()
            }
        } else if timerMode == .manual {
            let savedRemaining = defaults.integer(forKey: "ts_remainingSeconds")

            if stateStr == "paused" {
                remainingSeconds = savedRemaining
            } else if let segStart = defaults.object(forKey: "ts_segmentStartDate") as? Date {
                let elapsed = Int(Date().timeIntervalSince(segStart))
                remainingSeconds = max(savedRemaining - elapsed, 0)
            } else {
                remainingSeconds = savedRemaining
            }

            if remainingSeconds > 0 {
                segmentStartDate = Date()
                startTimerInternal()
                if stateStr == "paused" {
                    pauseTimer()
                }
            } else {
                clearScheduleState()
                clearPersistedState()
            }
        }
    }
}
