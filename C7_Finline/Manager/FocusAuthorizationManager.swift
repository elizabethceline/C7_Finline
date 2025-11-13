//
//  FocusAuthorizationManager.swift
//  C7_Finline
//
//  Created by Gabriella Natasya Pingky Davis on 03/11/25.
//


import Foundation
import SwiftUI
import Combine

#if os(iOS)
import ManagedSettings
import FamilyControls
#endif

final class FocusAuthorizationManager: ObservableObject {
    @Published var isEnabled: Bool = true {
        didSet {
            Task { await handleToggleChange() }
        }
    }
    @Published var isAuthorized: Bool = false
    @Published var errorMessage: String?
    
    #if os(iOS)
    @Published var selection = FamilyActivitySelection()
    private let managedStore = ManagedSettingsStore()
    #endif
    
    private let selectionDefaultsKey = "FocusSelectionData"
    
    init() {
        loadSelection()
        updateAuthorizationStatus()
    }
    
    func applyShield() {
        #if os(iOS)
        if selection.applicationTokens.isEmpty && selection.webDomainTokens.isEmpty {
            managedStore.shield.applicationCategories = .all()
            managedStore.shield.webDomainCategories = .all()
        } else {
            managedStore.shield.applications = selection.applicationTokens
            managedStore.shield.webDomains = selection.webDomainTokens
        }
        print("Deep Focus shield applied")
        #endif
    }
    
    func clearShield() {
        #if os(iOS)
        managedStore.shield.applications = nil
        managedStore.shield.webDomains = nil
        managedStore.shield.applicationCategories = nil
        managedStore.shield.webDomainCategories = nil
        print("Deep Focus shield cleared")
        #endif
    }
    
    func requestAuthorization() async {
        #if os(iOS)
        do {
            let center = AuthorizationCenter.shared
            switch center.authorizationStatus {
            case .notDetermined, .denied:
                try await center.requestAuthorization(for: .individual)
            default:
                break
            }
            await MainActor.run {
                updateAuthorizationStatus()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                print("FamilyControls authorization error: \(error)")
            }
        }
        #else
        isAuthorized = false
        #endif
    }
    
    private func updateAuthorizationStatus() {
        #if os(iOS)
        let status = AuthorizationCenter.shared.authorizationStatus
        isAuthorized = (status == .approved)
        #else
        isAuthorized = false
        #endif
    }
    
    @MainActor
    private func handleToggleChange() async {
        if isEnabled {
            #if os(iOS)
            let status = AuthorizationCenter.shared.authorizationStatus
            if status != .approved {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    updateAuthorizationStatus()
                } catch {
                    self.errorMessage = error.localizedDescription
                    print("Authorization request failed: \(error)")
                    isEnabled = false // revert toggle if it failed
                    return
                }
            } else {
                updateAuthorizationStatus()
            }
            #else
            isAuthorized = false
            #endif

            print("Deep Focus enabled, authorized: \(isAuthorized)")
//             Shield will be applied later when session starts
        } else {
            clearShield()
            print("Deep Focus disabled manually")
        }
    }
    
    func saveSelection() {
        #if os(iOS)
        do {
            let data = try JSONEncoder().encode(selection)
            UserDefaults.standard.set(data, forKey: selectionDefaultsKey)
        } catch {
            print("Failed to encode selection: \(error)")
        }
        #endif
    }
    
    private func loadSelection() {
        #if os(iOS)
        guard let data = UserDefaults.standard.data(forKey: selectionDefaultsKey) else { return }
        if let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = decoded
        }
        #endif
    }
}
