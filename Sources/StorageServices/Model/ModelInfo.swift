// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

struct ModelInfo {
    let modelType: ModelType
    let modelURL: URL
    let sizeInBytes: Int64
    let creationDate: Date
    let projectModelInfo: ProjectModelInfo?
}

#if DEBUG

extension ModelInfo {
    static var fake: ModelInfo {
        .init(
            modelType: .imageClassifier,
            modelURL: URL.temporaryDirectory.appendingPathComponent("foo.mlmodel"),
            sizeInBytes: Int64(15_325),
            creationDate: .date5,
            projectModelInfo: nil
        )
    }
}

#endif
