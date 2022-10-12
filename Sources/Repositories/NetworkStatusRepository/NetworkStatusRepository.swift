// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// A repository that monitors network connectivity status.
protocol NetworkStatusRepository: Sendable {

    /// Starts observing network status using `NWPathMonitor`
    func startMonitoring() async

    /// Stops observing network status using `NWPathMonitor`
    func stopMonitoring() async

    /// Returns whether this repository thinks the network is online or not.
    /// - Note: This property is `false` by default if monitoring was never started,
    /// so it is recommended to start monitoring first before querying this value.
    var isOnline: Bool { get async }
}
