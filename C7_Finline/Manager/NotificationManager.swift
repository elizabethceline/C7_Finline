//
//  NotificationManager.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 13/11/25.
//

import Combine
import Foundation
import SwiftData
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let taskReminderPrefix = "task_reminder_"
    private let taskCompletionPrefix = "task_completion_"
    private let restEndNotificationID = "rest_end_notification"
    private let focusEndNotificationID = "focus_end_notification"

    private init() {
        Task {
            await resetBadge()
        }
    }

    // Reset badge count
    func resetBadge() async {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print(
                        "Failed to reset badge count: \(error.localizedDescription)"
                    )
                } else {
                    print("Badge count reset to 0")
                }
                continuation.resume()
            }
        }
    }

    func scheduleNotificationsForTasks(_ tasks: [GoalTask], username: String)
        async
    {
        await removeAllTaskNotifications()

        let now = Date()
        let validTasks = tasks.filter { task in
            !task.isCompleted && task.workingTime > now
        }

        print("Scheduling notifications for \(validTasks.count) tasks")

        for task in validTasks {
            await scheduleReminderNotification(for: task, username: username)
            await scheduleCompletionReminderNotification(
                for: task,
                username: username
            )
        }
    }

    // notif 10 mins before task starts
    private func scheduleReminderNotification(
        for task: GoalTask,
        username: String
    ) async {
        let notificationTime = task.workingTime.addingTimeInterval(-10 * 60)

        // dont schedule if notification time is in the past
        guard notificationTime > Date() else {
            print(
                "Skipping notification for task '\(task.name)' - time already passed"
            )
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body =
            "Hi, \(username)! Your task '\(task.name)' is starting in 10 minutes. Get ready to focus!"
        content.sound = .default
        content.badge = 1

        content.userInfo = [
            "taskId": task.id,
            "taskName": task.name,
            "goalId": task.goal?.id ?? "",
            "workingTime": ISO8601DateFormatter().string(
                from: task.workingTime
            ),
            "notificationType": "reminder",
        ]

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notificationTime
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerDate,
            repeats: false
        )

        let identifier = taskReminderPrefix + task.id
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print(
                "Scheduled reminder notification for task '\(task.name)' at \(notificationTime)"
            )
        } catch {
            print(
                "Failed to schedule reminder notification for task '\(task.name)': \(error.localizedDescription)"
            )
        }
    }

    // notif 15 mins after task should be completed
    private func scheduleCompletionReminderNotification(
        for task: GoalTask,
        username: String
    ) async {
        // end time = workingTime + focusDuration
        let taskEndTime = task.workingTime.addingTimeInterval(
            TimeInterval(task.focusDuration * 60)
        )
        let notificationTime = taskEndTime.addingTimeInterval(15 * 60)  // 15 mins

        // dont schedule if notification time is in the past
        guard notificationTime > Date() else {
            print(
                "Skipping completion reminder for task '\(task.name)' - time already passed"
            )
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Task Completion Reminder"
        content.body =
            "Hi, \(username)! Did you complete '\(task.name)'? Don't forget to mark it as done!"
        content.sound = .default
        content.badge = 1

        content.userInfo = [
            "taskId": task.id,
            "taskName": task.name,
            "goalId": task.goal?.id ?? "",
            "workingTime": ISO8601DateFormatter().string(
                from: task.workingTime
            ),
            "notificationType": "completion_reminder",
        ]

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notificationTime
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerDate,
            repeats: false
        )

        let identifier = taskCompletionPrefix + task.id
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print(
                "Scheduled completion reminder for task '\(task.name)' at \(notificationTime)"
            )
        } catch {
            print(
                "Failed to schedule completion reminder for task '\(task.name)': \(error.localizedDescription)"
            )
        }
    }

    func scheduleRestEndNotification(
        username: String,
        restDuration: TimeInterval
    ) async {
        let content = UNMutableNotificationContent()
        content.title = "Rest Time's Up!"
        content.body =
            "Hey \(username)! Your rest is over. Time to get back to work and stay focused!"
        content.sound = .default
        content.badge = 1

        content.userInfo = [
            "notificationType": "rest_end"
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: restDuration,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: restEndNotificationID,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("Scheduled rest end notification for \(restDuration) seconds")
        } catch {
            print(
                "Failed to schedule rest end notification: \(error.localizedDescription)"
            )
        }
    }

    func scheduleSessionEndNotification(
        username: String,
        sessionDuration: TimeInterval
    ) async {
        let content = UNMutableNotificationContent()
        content.title = "Focus Session Complete!"
        content.body =
            "Great job, \(username)! You've completed your focus session. Have you done your tasks?"
        content.sound = .default
        content.badge = 1

        content.userInfo = [
            "notificationType": "focus_end"
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: sessionDuration,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: focusEndNotificationID,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print(
                "Scheduled focus end notification for \(sessionDuration) seconds"
            )
        } catch {
            print(
                "Failed to schedule focus end notification: \(error.localizedDescription)"
            )
        }
    }

    func cancelRestEndNotification() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [restEndNotificationID]
        )
        print("Cancelled rest end notification")
    }

    func cancelSessionEndNotification() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [focusEndNotificationID]
        )
        print("Cancelled session end notification")
    }

    func removeAllTaskNotifications() async {
        let pendingNotifications =
            await notificationCenter.pendingNotificationRequests()
        let taskNotificationIds =
            pendingNotifications
            .filter {
                $0.identifier.hasPrefix(taskReminderPrefix)
                    || $0.identifier.hasPrefix(taskCompletionPrefix)
            }
            .map { $0.identifier }

        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: taskNotificationIds
        )
        print("Removed \(taskNotificationIds.count) pending task notifications")
    }

    func removeNotification(for taskId: String) {
        let reminderIdentifier = taskReminderPrefix + taskId
        let completionIdentifier = taskCompletionPrefix + taskId

        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [reminderIdentifier, completionIdentifier]
        )
        print("Removed notifications for task: \(taskId)")
    }

    func logPendingNotifications() async {
        let pending = await notificationCenter.pendingNotificationRequests()
        print("=== Pending Notifications (\(pending.count)) ===")
        for request in pending {
            if request.identifier.hasPrefix(taskReminderPrefix)
                || request.identifier.hasPrefix(taskCompletionPrefix)
            {
                if let trigger = request.trigger
                    as? UNCalendarNotificationTrigger,
                    let nextTriggerDate = trigger.nextTriggerDate()
                {
                    let type =
                        request.identifier.hasPrefix(taskReminderPrefix)
                        ? "Reminder" : "Completion"
                    print(
                        "- [\(type)] \(request.content.title): \(request.content.body)"
                    )
                    print("  Scheduled for: \(nextTriggerDate)")
                }
            } else if request.identifier == restEndNotificationID
                || request.identifier == focusEndNotificationID
            {
                let type =
                    request.identifier == restEndNotificationID
                    ? "Rest End" : "Focus End"
                print(
                    "- [\(type)] \(request.content.title): \(request.content.body)"
                )
            }
        }
        print("=====================================")
    }
}

extension NotificationManager {
    // call this after syncing tasks
    func handleSyncCompletion(modelContext: ModelContext, username: String)
        async
    {
        do {
            let tasks = try modelContext.fetch(FetchDescriptor<GoalTask>())
            await scheduleNotificationsForTasks(tasks, username: username)
            await logPendingNotifications()
        } catch {
            print(
                "Failed to fetch tasks for notification scheduling: \(error.localizedDescription)"
            )
        }
    }
}
