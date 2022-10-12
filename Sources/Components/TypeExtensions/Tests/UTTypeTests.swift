// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
import UniformTypeIdentifiers
@testable import CoMLApp

final class UTTypeTests: XCTestCase {
    func testFileNameExtensionForPNGIsPNG() throws {
        XCTAssertEqual(try UTType.png.fileNameExtension(), "png")
    }

    func testFileNameExtensionForDefaultImageIsPNG() throws {
        XCTAssertEqual(try UTType.image.fileNameExtension(), "png")
    }

    func testFileNameExtensionForJpegIsJPEG() throws {
        XCTAssertEqual(try UTType.jpeg.fileNameExtension(), "jpeg")
    }

    func testFileNameExtensionForUnsupportedTypes() {
        let unsupportedTypes: [UTType] = [
            .movie, .video, .mp3, .audio, .quickTimeMovie,
            .mpeg, .mpeg2Video, .mpeg2TransportStream,
            .mpeg4Movie, .mpeg4Audio
        ]

        for unsupportedType in unsupportedTypes {
            XCTAssertThrowsError(try unsupportedType.fileNameExtension())
        }
    }
}
