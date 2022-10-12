// Copyright 2026 Apple Inc. All rights reserved.

@testable import CoMLApp
import XCTest

final class PredictionResultChartTest: XCTestCase {
    func testPredictionsAreSortedAlphabeticallyExceptTopPrediction() throws {
        let data: [Observation] = [.init(annotation: "Mango", confidence: 0.43),
                                           .init(annotation: "Lemon", confidence: 0.21),
                                           .init(annotation: "Orange", confidence: 0.11),
                                           .init(annotation: "Blueberry", confidence: 0.1),
                                           .init(annotation: "Strawberry", confidence: 0.05),
                                           .init(annotation: "Cherry", confidence: 0.05),
                                           .init(annotation: "Apple", confidence: 0.03),
                                           .init(annotation: "Banana", confidence: 0.0)]
        let sortedData = data.stableFirstWithRestSorted
        let correctlySortedData: [Observation] = [.init(annotation: "Mango", confidence: 0.43),
                                                          .init(annotation: "Apple", confidence: 0.03),
                                                          .init(annotation: "Banana", confidence: 0.0),
                                                          .init(annotation: "Blueberry", confidence: 0.1),
                                                          .init(annotation: "Cherry", confidence: 0.05),
                                                          .init(annotation: "Lemon", confidence: 0.21),
                                                          .init(annotation: "Orange", confidence: 0.11),
                                                          .init(annotation: "Strawberry", confidence: 0.05)]
        XCTAssertTrue(sortedData.elementsEqual(correctlySortedData) { $0.annotation == $1.annotation })
    }

    func testEmptyArrayBehavior() throws {
        let data: [Observation] = []
        let sortedData = data.stableFirstWithRestSorted
        let correctlySortedData: [Observation] = []
        XCTAssertTrue(sortedData.elementsEqual(correctlySortedData) { $0.annotation == $1.annotation })
    }

    func testArrayWithOneElementBehavior() throws {
        let data: [Observation] = [.init(annotation: "Apple", confidence: 0.99)]
        let sortedData = data.stableFirstWithRestSorted
        let correctlySortedData: [Observation] = [.init(annotation: "Apple", confidence: 0.99)]
        XCTAssertTrue(sortedData.elementsEqual(correctlySortedData) { $0.annotation == $1.annotation })
    }

    func testPredictionsWithFirstPlaceTieAreSortedCorrectly() throws {
        let data: [Observation] = [.init(annotation: "Orange", confidence: 0.48),
                                           .init(annotation: "Lemon", confidence: 0.48),
                                           .init(annotation: "Strawberry", confidence: 0.02),
                                           .init(annotation: "Blueberry", confidence: 0.02)]
        let sortedData = data.stableFirstWithRestSorted
        let correctlySortedData: [Observation] = [.init(annotation: "Orange", confidence: 0.48),
                                                          .init(annotation: "Blueberry", confidence: 0.02),
                                                          .init(annotation: "Lemon", confidence: 0.48),
                                                          .init(annotation: "Strawberry", confidence: 0.02)]
        XCTAssertTrue(sortedData.elementsEqual(correctlySortedData) { $0.annotation == $1.annotation })
    }
}
