// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

struct ProjectInfo {
    let prettyModelName: String
    let projectType: ModelType
    let dateTrained: Date?
    let documentType: String
    let sizeInBytes: Int64
    let labelNames: [String]

    static func modelNameFromTitle(_ projectTitle: String) -> String {
        let components = projectTitle.components(separatedBy: " ").map { word in
            var sanitized = word
            sanitized.unicodeScalars.removeAll(where: { !CharacterSet.alphanumerics.contains($0) })
            return sanitized.capitalized
        }
        let formattedTitle = components.joined()
        return formattedTitle + ".mlmodel"
    }
}

#if DEBUG

extension ProjectInfo {
    static let fake: Self = .init(
        prettyModelName: modelNameFromTitle("Fruit Classifier"),
        projectType: .imageClassifier,
        dateTrained: .date1,
        documentType: "Core ML Model",
        sizeInBytes: Int64.random(in: 10 ... 100),
        labelNames: .fakeFewLabelNames
    )

    static let manyLabels: Self = .init(
        prettyModelName: modelNameFromTitle("Fruit Classifier"),
        projectType: .imageClassifier,
        dateTrained: .date1,
        documentType: "Core ML Model",
        sizeInBytes: Int64.random(in: 10 ... 100),
        labelNames: .fakeManyLabelNames
    )
}

private extension [String] {

    static let fakeFewLabelNames: Self = [
        "Dog",
        "Cat",
        "Frog"
    ]

    static let fakeManyLabelNames: Self = [
        "Apple",
        "Banana",
        "Carrot",
        "Egg",
        "Fennel",
        "Giraffe",
        "House",
        "Iguana",
        "Jello",
        "Kangaroo",
        "Llama",
        "Monarch",
        "Nectarine",
        "Orange",
        "Potato",
        "Quagmire",
        "Ratatouille",
        "Sandbox",
        "Trinidad",
        "Umbrella",
        "Venti",
        "Wagon",
        "Yam",
        "Zoo"
    ]
}

#endif
