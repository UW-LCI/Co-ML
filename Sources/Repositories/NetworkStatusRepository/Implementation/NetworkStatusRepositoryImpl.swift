// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import Network
import os.log

actor NetworkStatusRepositoryImpl: NetworkStatusRepository {

    private var online = false
    private var numObservers = 0
    private var networkMonitor: NWPathMonitor?
    private let networkQueue = DispatchQueue(label: "NetworkMonitor-Repository")

    // MARK: - NetworkStatusRepository

    func startMonitoring() async {
        numObservers += 1
        os_log(.debug, "Handling request to start monitoring network status… (\(self.numObservers) observers)")

        guard networkMonitor == nil else {
            os_log(.debug, "Already monitoring network status.")
            return
        }

        let networkMonitor = NWPathMonitor()
        networkMonitor.pathUpdateHandler = handleNetworkPathUpdate

        networkMonitor.start(queue: networkQueue)
        self.networkMonitor = networkMonitor

        os_log(.debug, "Started monitoring network status.")
    }

    func stopMonitoring() async {
        os_log(.debug, "Handling request to stop monitoring network status…")

        numObservers -= 1
        if numObservers > 0 {
            os_log(.debug, "There are still \(self.numObservers) network status observers, not stopping.")
            return
        }

        guard let networkMonitor else {
            os_log(.error, "ERROR! Unexpectedly no network status monitor.")
            return
        }

        networkMonitor.cancel()
        self.networkMonitor = nil

        os_log(.debug, "Stopped monitoring network status.")
    }

    var isOnline: Bool {
        get async {
            online
        }
    }

    // MARK: - Private

    func handleNetworkPathUpdate(_ path: NWPath) {
        Task {
            await setOnline(path.status == .satisfied)
        }
    }

    func setOnline(_ online: Bool) async {
        self.online = online
    }
}
