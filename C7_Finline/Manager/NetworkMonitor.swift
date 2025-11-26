//
//  NetworkMonitor.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 23/10/25.
//

import Combine
import Foundation
import Network
import SwiftUI

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    @Published var isConnected: Bool = false

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            let connected = (path.status == .satisfied)

            DispatchQueue.main.async {
                if self.isConnected != connected {
                    self.isConnected = connected
                    print(
                        "Network Status Changed: \(connected ? "Connected" : "Disconnected")"
                    )
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
