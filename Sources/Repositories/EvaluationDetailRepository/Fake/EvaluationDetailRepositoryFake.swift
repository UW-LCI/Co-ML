// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

actor EvaluationDetailRepositoryFake: EvaluationDetailRepository {
    let sampleID: UUID
    var evaluationDetails: EvaluationDetails

    init(sampleID: UUID, evaluationDetails: EvaluationDetails) {
        self.sampleID = sampleID
        self.evaluationDetails = evaluationDetails
    }

    func fetchEvaluationDetails() async throws -> EvaluationDetails {
        evaluationDetails
    }

    func changeExpectedLabel(labelID: LabelID) async throws {
        evaluationDetails = EvaluationDetails(image: evaluationDetails.image,
                                              labels: evaluationDetails.labels,
                                              expectedLabelID: labelID)
    }

    func deleteSample() async throws {
        // No-op
    }

    func moveToTrainingData() async throws {
        // No-op
    }
}
