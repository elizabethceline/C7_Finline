//
//  NetworkMonitor.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 23/10/25.
//

import Foundation
import Network
import Combine
import SwiftUI

@MainActor
class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    @Published var isConnected: Bool = false

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let weakSelf = self

            Task { @MainActor in
                guard let strongSelf = weakSelf else { return }

                let connected = (path.status == .satisfied)

                if strongSelf.isConnected != connected {
                    strongSelf.isConnected = connected
                    print(
                        "Network Status Changed: \(connected ? "Connected" : "Disconnected")"
                    )
                }
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}
