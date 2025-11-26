//
//  BackgroundSyncManager.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 10/11/25.
//

import CloudKit
import Combine
import Foundation
import SwiftData
import UIKit
import UserNotifications

class BackgroundSyncManager: NSObject, ObservableObject {
    static let shared = BackgroundSyncManager()

    private let goalSubscriptionID = "goals-changes"
    private let taskSubscriptionID = "tasks-changes"
    private let profileSubscriptionID = "profile-changes"
    private let shopSubscriptionID = "shop-changes"

    private let cloudKit = CloudKitManager.shared
    private let networkMonitor: NetworkMonitor
    private let goalManager: GoalManager
    private let taskManager: TaskManager
    private let userProfileManager: UserProfileManager
    private let shopManager: ShopManager
    private let notificationManager = NotificationManager.shared

    @Published var lastSyncDate: Date?
    @Published var isSyncing = false
    @Published var syncError: String?

    private var cancellables = Set<AnyCancellable>()

    private override init() {
        self.networkMonitor = NetworkMonitor.shared
        self.goalManager = GoalManager(networkMonitor: networkMonitor)
        self.taskManager = TaskManager(networkMonitor: networkMonitor)
        self.userProfileManager = UserProfileManager(
            networkMonitor: networkMonitor
        )
        self.shopManager = ShopManager(networkMonitor: networkMonitor)

        super.init()

        loadLastSyncDate()
        setupNotificationObservers()
    }

    func setupCloudKitSubscriptions() async {
        guard CloudKitManager.shared.isSignedInToiCloud else {
            print("Not signed in to iCloud, skipping subscription setup")
            return
        }

        do {
            try await setupSubscription(
                recordType: "Goals",
                subscriptionID: goalSubscriptionID
            )

            try await setupSubscription(
                recordType: "Tasks",
                subscriptionID: taskSubscriptionID
            )

            try await setupSubscription(
                recordType: "UserProfile",
                subscriptionID: profileSubscriptionID
            )

            try await setupSubscription(
                recordType: "PurchasedItems",
                subscriptionID: shopSubscriptionID
            )

            print("All CloudKit subscriptions setup successfully")

        } catch {
            print(
                "Failed to setup CloudKit subscriptions: \(error.localizedDescription)"
            )
        }
    }

    private func setupSubscription(recordType: String, subscriptionID: String)
        async throws
    {
        // Check if subscription already exists
        do {
            _ = try await cloudKit.database.subscription(for: subscriptionID)
            print("Subscription '\(subscriptionID)' already exists")
            return
        } catch let error as CKError where error.code == .unknownItem {
            print("Creating new subscription '\(subscriptionID)'...")
        }

        // Create subscription
        let predicate = NSPredicate(value: true)  // Subscribe to all records
        let subscription = CKQuerySubscription(
            recordType: recordType,
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [
                .firesOnRecordCreation, .firesOnRecordUpdate,
                .firesOnRecordDeletion,
            ]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true  // Silent push
        notificationInfo.shouldBadge = false
        subscription.notificationInfo = notificationInfo

        // Save subscription
        _ = try await cloudKit.database.save(subscription)
        print("Created subscription '\(subscriptionID)' for \(recordType)")
    }

    func requestNotificationPermissions() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [
                .alert, .sound, .badge,
            ])
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                print("Notification permissions granted")
            } else {
                print("Notification permissions denied")
            }
            return granted
        } catch {
            print("Failed to request notification permissions: \(error)")
            return false
        }
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(
            for: NSNotification.Name("CKRemoteNotificationReceived")
        )
        .sink { [weak self] notification in
            self?.handleCloudKitNotification(notification)
        }
        .store(in: &cancellables)

        NotificationCenter.default.publisher(
            for: UIApplication.didBecomeActiveNotification
        )
        .sink { [weak self] _ in
            if self?.lastSyncDate == nil {
                Task {
                    await self?.performSync(reason: "Initial sync")
                }
            }
        }
        .store(in: &cancellables)
    }

    func handleCloudKitNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let notification = CKNotification(
                fromRemoteNotificationDictionary: userInfo
            )
        else {
            return
        }

        if let queryNotification = notification as? CKQueryNotification {
            handleQueryNotification(queryNotification)
        } else if let recordZoneNotification = notification
            as? CKRecordZoneNotification
        {
            handleRecordZoneNotification(recordZoneNotification)
        }
    }

    private func handleQueryNotification(_ notification: CKQueryNotification) {
        guard let subscriptionID = notification.subscriptionID,
            let recordID = notification.recordID
        else {
            return
        }

        let reason = notification.queryNotificationReason
        let recordType = recordID.recordName

        print("Received CloudKit notification:")
        print("Subscription: \(subscriptionID)")
        print("Record: \(recordType)")
        print("Reason: \(reasonDescription(reason))")

        Task {
            await performSync(
                reason: "CloudKit update (\(reasonDescription(reason)))"
            )
        }
    }

    private func handleRecordZoneNotification(
        _ notification: CKRecordZoneNotification
    ) {
        print("Received Record Zone notification")

        Task {
            await performSync(reason: "CloudKit zone update")
        }
    }

    @discardableResult
    func performSync(
        modelContext: ModelContext? = nil,
        reason: String = "Unknown"
    ) async -> Bool {
        guard !isSyncing else {
            print("Sync already in progress, skipping")
            return false
        }

        guard networkMonitor.isConnected else {
            print("Cannot sync: No network connection")
            return false
        }

        guard CloudKitManager.shared.isSignedInToiCloud else {
            print("Cannot sync: Not signed in to iCloud")
            return false
        }

        await MainActor.run {
            isSyncing = true
            syncError = nil
        }

        print("Starting sync (reason: \(reason))...")

        var success = true

        let context: ModelContext
        if let modelContext = modelContext {
            context = modelContext
        } else {
            guard let container = getModelContainer() else {
                await MainActor.run {
                    isSyncing = false
                    syncError = "Failed to get model container"
                }
                return false
            }
            context = ModelContext(container)
        }

        do {
            // 1. Sync pending deletions
            await goalManager.syncPendingDeletions()
            await taskManager.syncPendingDeletions()
            await shopManager.syncPendingDeletions()

            // 2. Sync pending local changes
            await goalManager.syncPendingGoals(modelContext: context)
            await taskManager.syncPendingTasks(modelContext: context)
            await userProfileManager.syncPendingProfiles(modelContext: context)

            try? await Task.sleep(nanoseconds: 500_000_000)
            await shopManager.syncPendingItems(modelContext: context)

            // 3. Fetch latest data from cloud
            _ = try await goalManager.fetchGoals(modelContext: context)

            let goals = try context.fetch(FetchDescriptor<Goal>())
            _ = try await taskManager.fetchTasks(
                for: goals,
                modelContext: context
            )

            _ = try await shopManager.fetchPurchasedItemsFromCloud(
                modelContext: context
            )

            // 4. Save all changes
            try context.save()

            try? await Task.sleep(nanoseconds: 100_000_000)

            await MainActor.run {
                lastSyncDate = Date()
                saveLastSyncDate()

                NotificationCenter.default.post(
                    name: .syncDidComplete,
                    object: nil,
                    userInfo: ["modelContext": context]
                )

                NotificationCenter.default.post(
                    name: Notification.Name("ProfileDataDidSync"),
                    object: nil
                )
                NotificationCenter.default.post(
                    name: Notification.Name("ShopDataDidSync"),
                    object: nil
                )
            }

            await scheduleNotificationsAfterSync(modelContext: context)

            print("Sync completed successfully")

        } catch {
            success = false
            let errorMessage = "Sync failed: \(error.localizedDescription)"
            print("\(errorMessage)")

            await MainActor.run {
                syncError = errorMessage
            }

            NotificationCenter.default.post(
                name: .syncDidFail,
                object: nil,
                userInfo: ["error": error]
            )
        }

        await MainActor.run {
            isSyncing = false
        }

        return success
    }

    private func scheduleNotificationsAfterSync(modelContext: ModelContext)
        async
    {
        do {
            // Fetch user profile to get username
            guard let userRecordID = try? await cloudKit.fetchUserRecordID()
            else {
                print("Failed to fetch user record ID for notifications")
                return
            }

            let profile = try await userProfileManager.fetchProfile(
                userRecordID: userRecordID,
                modelContext: modelContext
            )

            let username = profile.username.isEmpty ? "there" : profile.username

            // Schedule notifications for all tasks
            await notificationManager.handleSyncCompletion(
                modelContext: modelContext,
                username: username
            )

        } catch {
            print(
                "Failed to schedule notifications after sync: \(error.localizedDescription)"
            )
        }
    }

    func triggerManualSync(modelContext: ModelContext) async {
        await performSync(modelContext: modelContext, reason: "Manual trigger")
    }

    var syncStatusMessage: String {
        if isSyncing {
            return "Syncing..."
        }

        if let error = syncError {
            return "Sync error: \(error)"
        }

        if let lastSync = lastSyncDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return
                "Last synced \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
        }

        return "Not synced yet"
    }

    private func reasonDescription(_ reason: CKQueryNotification.Reason)
        -> String
    {
        switch reason {
        case .recordCreated:
            return "Record Created"
        case .recordUpdated:
            return "Record Updated"
        case .recordDeleted:
            return "Record Deleted"
        @unknown default:
            return "Unknown"
        }
    }

    private func loadLastSyncDate() {
        if let timestamp = UserDefaults.standard.object(forKey: "lastSyncDate")
            as? Date
        {
            lastSyncDate = timestamp
        }
    }

    private func saveLastSyncDate() {
        if let date = lastSyncDate {
            UserDefaults.standard.set(date, forKey: "lastSyncDate")
        }
    }

    private func getModelContainer() -> ModelContainer? {
        let schema = Schema([
            UserProfile.self,
            Goal.self,
            GoalTask.self,
            PurchasedItem.self,
            FocusSessionResult.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            print("Failed to create ModelContainer: \(error)")
            return nil
        }
    }

    func removeAllSubscriptions() async {
        let subscriptionIDs = [
            goalSubscriptionID,
            taskSubscriptionID,
            profileSubscriptionID,
            shopSubscriptionID,
        ]

        for subscriptionID in subscriptionIDs {
            do {
                _ = try await cloudKit.database.deleteSubscription(
                    withID: subscriptionID
                )
                print("Removed subscription '\(subscriptionID)'")
            } catch {
                print(
                    "Failed to remove subscription '\(subscriptionID)': \(error)"
                )
            }
        }
    }
}

extension BackgroundSyncManager {

    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }
            .joined()
        print("Registered for remote notifications with token: \(tokenString)")
    }

    func didFailToRegisterForRemoteNotifications(withError error: Error) {
        print(
            "Failed to register for remote notifications: \(error.localizedDescription)"
        )
    }

    func didReceiveRemoteNotification(
        userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler:
            @escaping (UIBackgroundFetchResult) -> Void
    ) {
        if CKNotification(fromRemoteNotificationDictionary: userInfo) != nil {
            print("Received CloudKit remote notification")

            NotificationCenter.default.post(
                name: NSNotification.Name("CKRemoteNotificationReceived"),
                object: nil,
                userInfo: userInfo
            )

            Task {
                let success = await performSync(reason: "Remote notification")

                await MainActor.run {
                    completionHandler(success ? .newData : .failed)
                }
            }
        } else {
            completionHandler(.noData)
        }
    }
}
