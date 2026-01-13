// notification-manager.swift
// system notification delivery and permission management

import Foundation
import UserNotifications

/// manages system notifications for session completion
class NotificationManager {
    
    static let shared = NotificationManager()
    
    private init() {
        setupNotificationCategories()
    }
    
    /// request notification authorization from user
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("notification authorization failed: \(error)")
            return false
        }
    }
    
    /// send session complete notification
    func sendSessionComplete(type: SessionType) {
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro Timer"
        content.categoryIdentifier = "SESSION_COMPLETE"
        content.sound = .default
        
        switch type {
        case .work:
            content.body = "Work session complete! Time for a break."
            content.badge = 1
            
        case .shortBreak:
            content.body = "Break over! Ready to focus?"
            content.badge = 0
            
        case .longBreak:
            content.body = "Long break complete! Great work today."
            content.badge = 0
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("notification delivery failed: \(error)")
            }
        }
    }
    
    /// setup notification action categories
    private func setupNotificationCategories() {
        let startAction = UNNotificationAction(
            identifier: "START_NEXT",
            title: "Start Next Session",
            options: .foreground
        )
        
        let skipAction = UNNotificationAction(
            identifier: "SKIP_BREAK",
            title: "Skip Break",
            options: .foreground
        )
        
        let category = UNNotificationCategory(
            identifier: "SESSION_COMPLETE",
            actions: [startAction, skipAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    /// clear all delivered notifications
    func clearNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
