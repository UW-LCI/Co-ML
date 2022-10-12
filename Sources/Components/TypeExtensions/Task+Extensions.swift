// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: UInt64) async throws {
        try await sleep(nanoseconds: seconds * NSEC_PER_SEC)
    }
    static func sleep(milliseconds: UInt64) async throws {
        try await sleep(nanoseconds: milliseconds * NSEC_PER_MSEC)
    }
}
