//
//  TimerViewModel.swift
//  Pomos
//
//  Created by Assistant on 2025-12-15.
//

import SwiftUI
import UserNotifications
import AppKit

enum TimerMode {
    case initial
    case working
    case finished
    case breaking
}

@MainActor
class TimerViewModel: ObservableObject {
    @Published var mode: TimerMode = .initial
    @Published var secondsRemaining: Int = 0
    @Published var finishedCount: Int = 0
    @Published var endAt: Date? = nil
    @Published var sessionDuration: Int {
        didSet {
            UserDefaults.standard.set(sessionDuration, forKey: "PomosSessionDuration")
        }
    }
    
    var task: Task<(), Error>?
    let breakDuration = 5 * 60
    
    init() {
        // Set temporary default values
        let savedDuration = UserDefaults.standard.integer(forKey: "PomosSessionDuration")
        self.sessionDuration = savedDuration > 0 ? savedDuration : 50 * 60
        self.finishedCount = 0
    }
    
    func setupAsync() async {
        // Load stats
        let stats = await StatsService.shared.readStats()
        self.finishedCount = stats.finished

        // Request notification permission
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            print("Failed to request notification permission: \(error)")
        }
    }
    
    func startSession() {
        mode = .working
        startTimer(duration: sessionDuration)
    }
    
    func giveUp() {
        // In SwiftUI, we might handle the alert in the View, but we can reset here
        stopTimer()
        mode = .initial
        secondsRemaining = 0
        resetBadge()
    }
    
    func takeBreak() {
        mode = .breaking
        startTimer(duration: breakDuration)
    }
    
    func skipBreak() {
        startSession()
    }
    
    private func startTimer(duration: Int) {
        secondsRemaining = duration
        endAt = Date().addingTimeInterval(TimeInterval(duration))
        updateBadge()

        task = Task { [weak self] in
            while !Task.isCancelled {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                guard let self = self else { return }

                await self.tick()
            }
        }
    }
    
    private func stopTimer() {
        task?.cancel()
        task = nil
    }
    
    private func tick() async {
        guard let endAt = endAt else { return }
        let remaining = Int(endAt.timeIntervalSinceNow)
        secondsRemaining = max(0, remaining)
        updateBadge()
        
        if secondsRemaining <= 0 {
            await timerValidComplete()
        }
    }
    
    private func timerValidComplete() async {
        stopTimer()
        
        switch mode {
        case .working:
            mode = .finished
            finishedCount += 1
            await StatsService.shared.saveStats(DailyStats(date: Date(), finished: finishedCount))
            sendNotification(title: "Time Up!", body: "Take a break")
            secondsRemaining = breakDuration // Pre-set for display if needed
            
        case .breaking:
            mode = .initial
            sendNotification(title: "Back to work", body: "Ready?")
            secondsRemaining = sessionDuration // Pre-set
            
        default:
            break
        }
        
        resetBadge() // Or keep it? Original code resets on Finished/Initial logic.
        // Controller.m: resetBadge on Working->Finished.
    }
    
    // MARK: - Notifications & Badge
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func updateBadge() {
        let min = secondsRemaining / 60
        let sec = secondsRemaining % 60
        var label: String
        
        if min >= 5 {
            label = "\(min) min"
        } else if min >= 1 {
            // "min:00" or "min:30" approximation from original code
            let secApprox = (sec / 30) * 30
            label = String(format: "%d:%02d", min, secApprox)
        } else {
            if sec > 10 {
                label = "\(sec / 10 * 10) s"
            } else {
                label = "\(sec) s"
            }
        }
        
        NSApp.dockTile.badgeLabel = label
    }
    
    private func resetBadge() {
        NSApp.dockTile.badgeLabel = nil
    }
}

