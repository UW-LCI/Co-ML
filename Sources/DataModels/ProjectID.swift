// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

typealias ProjectID = UUID

#if DEBUG

extension ProjectID {
    static let fakeProjectID = ProjectID(uuidString: "1fe8b501-8e87-46e0-9891-0a90ade6652b")!
    static let fakeProjectID2 = ProjectID(uuidString: "2f85fb76-df2d-457d-a0d5-f7d9e01ce04c")!
    static let fakeProjectID3 = ProjectID(uuidString: "3f6edb1c-e686-4f5a-aec1-56bea5718afc")!
    static let fakeProjectID4 = ProjectID(uuidString: "4f1f3551-5a69-49c1-825e-2339c07d8ec6")!
    static let fakeProjectID5 = ProjectID(uuidString: "5f5bb95b-544c-4ad2-8e45-96dbed60d88c")!
}

#endif
