//
//  AppDelegate.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 10/11/25.
//

import CloudKit
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permissions and setup subscriptions
        Task {
            let granted = await BackgroundSyncManager.shared.requestNotificationPermissions()
            
            if granted {
                // Setup CloudKit subscriptions
                await BackgroundSyncManager.shared.setupCloudKitSubscriptions()
            }
        }
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        BackgroundSyncManager.shared.didRegisterForRemoteNotifications(
            withDeviceToken: deviceToken
        )
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        BackgroundSyncManager.shared.didFailToRegisterForRemoteNotifications(
            withError: error
        )
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        BackgroundSyncManager.shared.didReceiveRemoteNotification(
            userInfo: userInfo,
            fetchCompletionHandler: completionHandler
        )
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
