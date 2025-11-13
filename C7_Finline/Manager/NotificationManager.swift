//
//  NotificationManager.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 13/11/25.
//

import Foundation
import UserNotifications
import SwiftData
import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let taskNotificationPrefix = "task_reminder_"
    
    private init() {}
    
    func scheduleNotificationsForTasks(_ tasks: [GoalTask], username: String) async {
        await removeAllTaskNotifications()
        
        let now = Date()
        let validTasks = tasks.filter { task in
            !task.isCompleted && task.workingTime > now
        }
        
        print("Scheduling notifications for \(validTasks.count) tasks")
        
        for task in validTasks {
            await scheduleNotification(for: task, username: username)
        }
    }
    
    private func scheduleNotification(for task: GoalTask, username: String) async {
        let notificationTime = task.workingTime.addingTimeInterval(-10 * 60)
        
        // dont schedule if notification time is in the past
        guard notificationTime > Date() else {
            print("Skipping notification for task '\(task.name)' - time already passed")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = "Hi, \(username)! Your task '\(task.name)' is starting in 10 minutes. Get ready to focus!"
        content.sound = .default
        content.badge = 1
        
        content.userInfo = [
            "taskId": task.id,
            "taskName": task.name,
            "goalId": task.goal?.id ?? "",
            "workingTime": ISO8601DateFormatter().string(from: task.workingTime)
        ]
        
        // trigger
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notificationTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Create request
        let identifier = taskNotificationPrefix + task.id
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("Scheduled notification for task '\(task.name)' at \(notificationTime)")
        } catch {
            print("Failed to schedule notification for task '\(task.name)': \(error.localizedDescription)")
        }
    }
    
    func removeAllTaskNotifications() async {
        let pendingNotifications = await notificationCenter.pendingNotificationRequests()
        let taskNotificationIds = pendingNotifications
            .filter { $0.identifier.hasPrefix(taskNotificationPrefix) }
            .map { $0.identifier }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: taskNotificationIds)
        print("Removed \(taskNotificationIds.count) pending task notifications")
    }
    
    func removeNotification(for taskId: String) {
        let identifier = taskNotificationPrefix + taskId
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Removed notification for task: \(taskId)")
    }
    
    func checkNotificationPermission() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    func logPendingNotifications() async {
        let pending = await notificationCenter.pendingNotificationRequests()
        print("=== Pending Notifications (\(pending.count)) ===")
        for request in pending {
            if request.identifier.hasPrefix(taskNotificationPrefix) {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let nextTriggerDate = trigger.nextTriggerDate() {
                    print("- \(request.content.title): \(request.content.body)")
                    print("  Scheduled for: \(nextTriggerDate)")
                }
            }
        }
        print("=====================================")
    }
}

extension NotificationManager {
    // call this after syncing tasks
    func handleSyncCompletion(modelContext: ModelContext, username: String) async {
        do {
            let tasks = try modelContext.fetch(FetchDescriptor<GoalTask>())
            await scheduleNotificationsForTasks(tasks, username: username)
            await logPendingNotifications()
        } catch {
            print("Failed to fetch tasks for notification scheduling: \(error.localizedDescription)")
        }
    }
}
