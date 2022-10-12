// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
@testable import CoMLApp
import UIKit
import XCTest

final class ImageStreamerTests: XCTestCase {

    func testImagesSentAreReceivedByListener() async throws {
        let sut = ScaledImageStreamer()

        Task {
            for _ in 1...3 {
                try await Self.delayThenSendImage(using: sut)
            }
        }

        var count = 0
        for await _ in await sut.imagesPickedByUser() {
            count += 1
            if count == 3 {
                break
            }
        }
        try await Task.sleep(seconds: 5)
        XCTAssertEqual(count, 3)
    }

    private static func delayThenSendImage(using sut: ScaledImageStreamer) async throws {
        try await Task.sleep(seconds: 1)
        await sut.sendImage(UIImage())
    }
}
