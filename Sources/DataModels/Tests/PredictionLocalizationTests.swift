// Copyright 2026 Apple Inc. All rights reserved.

@testable import CoMLApp
import XCTest
@testable import CoMLApp

final class PredictionLocalizationTests: XCTestCase {
    func testLocalizedPredictionFormatting() {
        XCTAssertEqual(0.0333.localizedConfidenceDisplayText, "3%")
        XCTAssertEqual(0.039.localizedConfidenceDisplayText, "4%")
        XCTAssertEqual(0.1.localizedConfidenceDisplayText, "10%")
        XCTAssertEqual(0.824.localizedConfidenceDisplayText, "82%")
    }
}
