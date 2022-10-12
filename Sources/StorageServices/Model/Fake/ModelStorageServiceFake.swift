// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

#if DEBUG

struct ModelStorageServiceFake: ModelStorageService {

    let projectID: ProjectID
    let anyModelExists: Bool
    let modelInfo: ModelInfo?
    let modelURL: URL

    init(projectID: ProjectID = .init(), anyModelExists: Bool = true, modelInfo: ModelInfo? = nil) {
        self.projectID = projectID
        self.anyModelExists = anyModelExists
        self.modelInfo = modelInfo
        modelURL = self.modelInfo?.modelURL ?? ModelInfo.fake.modelURL
    }

    var modelType: ModelType {
        .imageClassifier
    }

    func fetchModelInfo() async -> ModelInfo? {
        modelInfo
    }
}

extension ModelStorageService where Self == ModelStorageServiceFake {
    static func fake(
        projectID: ProjectID = .fakeProjectID
    ) -> Self {
        .init(
            projectID: projectID,
            anyModelExists: true,
            modelInfo: .fake
        )
    }

    static func fakeNoModel(
        projectID: ProjectID = .fakeProjectID
    ) -> Self {
        .init(
            projectID: projectID,
            anyModelExists: false,
            modelInfo: nil
        )
    }
}

#endif
