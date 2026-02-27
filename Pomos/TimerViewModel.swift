import Foundation
import AppKit
import Combine
import UserNotifications

final class TimerViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var state: TimerState = .idle
    @Published var remainingSeconds: Int
    @Published var finishedCount: Int = 0
    @Published var endTimeText: String = ""
    @Published var buttonTitle: String = "Start"
    @Published var sessionMinutes: Int = 50

    // MARK: - Private Properties

    private let storage = StorageService.shared
    private let notifications = NotificationService.shared

    private var timer: Timer?
    private var endAt: Date?
    private let breakLength = 5 * 60 // 5 minutes

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    // MARK: - Initialization

    private let defaultSessionDuration = 50 * 60 // 50 minutes in seconds

    init() {
        let stored = storage.sessionDuration
        let duration = stored > 0 ? stored : defaultSessionDuration
        remainingSeconds = duration
        sessionMinutes = duration / 60
        finishedCount = storage.checkAndResetIfNewDay()
        updateUI()

        notifications.requestAuthorization { _ in }
        notifications.onNotificationTapped = { [weak self] in
            self?.handleNotificationTap()
        }
    }

    // MARK: - Public Actions

    func onButtonClick() {
        switch state {
        case .working:
            break // Handled by View with confirmation dialog
        case .breaking:
            skipBreak()
        default:
            nextState()
        }
    }

    func configureSessionDuration(_ minutes: Int) {
        sessionMinutes = minutes
        storage.sessionDuration = minutes * 60
        if state == .idle {
            remainingSeconds = minutes * 60
            updateUI()
        }
    }

    // MARK: - Private Methods

    private func nextState() {
        notifications.removeAllDeliveredNotifications()
        finishedCount = storage.checkAndResetIfNewDay()

        switch state {
        case .idle:
            startWorking()
        case .finished:
            startBreaking()
        case .breaking:
            resetToIdle()
        case .working:
            break // Handled by alert
        }
    }

    private func startWorking() {
        state = .working
        endAt = Date().addingTimeInterval(TimeInterval(storage.sessionDuration))
        remainingSeconds = storage.sessionDuration

        startTimer()
        updateEndTimeLabel()
        updateButtonTitle()
        updateDockBadge()
    }

    private func startBreaking() {
        state = .breaking
        endAt = Date().addingTimeInterval(TimeInterval(breakLength))
        remainingSeconds = breakLength

        startTimer()
        updateEndTimeLabel()
        updateButtonTitle()
        updateDockBadge()
    }

    private func resetToIdle() {
        state = .idle
        remainingSeconds = storage.sessionDuration
        endAt = nil

        timer?.invalidate()
        timer = nil
        resetDockBadge()
        updateEndTimeLabel()
        updateButtonTitle()
    }

    private func workFinished() {
        state = .finished
        timer?.invalidate()
        timer = nil

        remainingSeconds = breakLength
        finishedCount = storage.incrementAndSave()

        resetDockBadge()
        updateButtonTitle()
        notifications.sendNotification(title: "Time Up!", body: "Take a break")
    }

    private func breakFinished() {
        state = .idle
        timer?.invalidate()
        timer = nil

        remainingSeconds = storage.sessionDuration
        endAt = nil

        resetDockBadge()
        updateEndTimeLabel()
        updateButtonTitle()
        notifications.sendNotification(title: "Back to work", body: "Sure")
    }

    private func skipBreak() {
        timer?.invalidate()
        timer = nil
        resetToIdle()
    }

    func confirmGiveUp() {
        // User chose to give up - go back to idle, no break
        state = .idle
        timer?.invalidate()
        timer = nil

        remainingSeconds = sessionMinutes * 60
        endAt = nil

        resetDockBadge()
        updateEndTimeLabel()
        updateButtonTitle()
    }

    func cancelGiveUp() {
        // Do nothing, just dismiss
    }

    func showGiveUpAlert() {
        guard let window = NSApplication.shared.keyWindow else { return }

        let alert = NSAlert()
        alert.messageText = "Are you sure to give up this pomodoro?"
        let yesButton = alert.addButton(withTitle: "Yes")
        let cancelButton = alert.addButton(withTitle: "It's a slip")
        yesButton.keyEquivalent = "\r"
        cancelButton.keyEquivalent = "\u{1B}"
        cancelButton.isBordered = true

        alert.beginSheetModal(for: window) { response in
            if response == .alertFirstButtonReturn {
                self.confirmGiveUp()
            }
        }
    }

    private func handleNotificationTap() {
        guard timer == nil else { return }

        if state == .finished || state == .idle {
            nextState()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
                self.updateDockBadge()
                if self.remainingSeconds <= 0 {
                    switch self.state {
                    case .working:
                        self.workFinished()
                    case .breaking:
                        self.breakFinished()
                    default:
                        break
                    }
                }
            }
        }
    }

    private func tick() {
        // Not used anymore
    }

    private func updateUI() {
        updateButtonTitle()
        updateEndTimeLabel()
    }

    private func updateButtonTitle() {
        switch state {
        case .idle:
            buttonTitle = "Start"
        case .working:
            buttonTitle = "Give up"
        case .finished:
            buttonTitle = "Break"
        case .breaking:
            buttonTitle = "Skip"
        }
    }

    private func updateEndTimeLabel() {
        if let endAt = endAt {
            endTimeText = "Ends at \(dateFormatter.string(from: endAt))"
        } else {
            endTimeText = ""
        }
    }

    // MARK: - Dock Badge

    private func updateDockBadge() {
        guard state == .working || state == .breaking else {
            resetDockBadge()
            return
        }

        let min = remainingSeconds / 60
        let sec = remainingSeconds % 60
        var badge: String

        if min >= 5 {
            badge = "\(min) min"
        } else if min >= 1 {
            badge = String(format: "%d:%02d", min, (sec / 30) * 30)
        } else {
            if sec > 10 {
                badge = "\((sec / 10) * 10) s"
            } else {
                badge = "\(sec) s"
            }
        }

        NSApplication.shared.dockTile.badgeLabel = badge
    }

    private func resetDockBadge() {
        NSApplication.shared.dockTile.badgeLabel = nil
    }
}
