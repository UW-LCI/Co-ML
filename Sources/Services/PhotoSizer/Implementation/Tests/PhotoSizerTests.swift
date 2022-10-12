// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
@testable import CoMLApp
import UIKit
import XCTest

final class PhotoSizerTests: XCTestCase {

    func testImageGetsCroppedToCorrectSize() {
        let photoSizer = PhotoSizerImpl()
        let image = UIImage(systemName: "camera")!
        let result = photoSizer.scaleAndCrop(image: image)
        XCTAssertEqual(result.size.width, 299)
        XCTAssertEqual(result.size.height, 299)
    }
}
