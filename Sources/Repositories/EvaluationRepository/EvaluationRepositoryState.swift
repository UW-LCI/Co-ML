// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

enum EvaluationRepositoryState {
    case noModel(EvaluationRepositoryInfo)
    case evaluationCompleted(EvaluationRepositoryInfo)
    case failed(Error)
}

extension EvaluationRepositoryState {

    var briefDescription: String {
        switch self {
        case .noModel(let info):
            return "No model with \(info.briefDescription)"
        case .evaluationCompleted(let info):
            return "Done with \(info.briefDescription)"
        case .failed(let error):
            return "Failed with error \(error)"
        }
    }

    var isCompleted: Bool {
        switch self {
        case .failed, .noModel:
            return false
        case .evaluationCompleted:
            return true
        }
    }
}
