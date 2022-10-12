// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

enum EvaluationDescriptiveLabelState: Identifiable, Equatable {
    case correct(labelName: String)
    case incorrect(wrongLabelName: String, expectedLabelName: String)

    var isCorrect: Bool {
        switch self {
        case .correct:
            return true
        case .incorrect:
            return false
        }
    }

    // MARK: - Identifiable

    var id: String {
        switch self {
        case .correct(let labelName):
            return "Correct-\(labelName)"
        case .incorrect(let wrongLabelName, let expectedLabelName):
            return "Incorrect-\(wrongLabelName)-expected-\(expectedLabelName)"
        }
    }
}
