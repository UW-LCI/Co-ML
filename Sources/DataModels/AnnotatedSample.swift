// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import UniformTypeIdentifiers

struct AnnotatedSample: Codable, Sendable {
    var id = UUID()
    var annotation: LabelAnnotation
    var sampleType: UTType
    var sampleData: Data
    var creationDate: Date
}

#if DEBUG

extension AnnotatedSample {
    static let fakeApple1Sample: Self = .init(
        id: .fakeApple1SampleUUID,
        annotation: .fakeAppleLabel,
        sampleType: .jpeg,
        sampleData: "FakeApple1Sample".data(using: .utf8)!,
        creationDate: .init(timeIntervalSince1970: 1_776_286_959)
    )

    static let fakeApple2Sample: Self = .init(
        id: .fakeApple2SampleUUID,
        annotation: .fakeAppleLabel,
        sampleType: .jpeg,
        sampleData: "FakeApple2Sample".data(using: .utf8)!,
        creationDate: .init(timeIntervalSince1970: 1_776_286_969)
    )

    static let fakeBanana1Sample: Self = .init(
        id: .fakeBanana1SampleUUID,
        annotation: .fakeBananaLabel,
        sampleType: .jpeg,
        sampleData: "FakeBanana1Sample".data(using: .utf8)!,
        creationDate: .init(timeIntervalSince1970: 1_776_286_979)
    )
}

#endif
