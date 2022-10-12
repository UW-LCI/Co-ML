// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import CoreData

enum PredicateType {
    case lessThan(CVarArg), greaterThan(CVarArg), equalTo(CVarArg)
}

// Convenient, type safe way of building up a `NSPredicate`.
struct Predicate {
    let type: PredicateType
    let key: String

    var formatted: (format: String, value: any CVarArg) {
        switch type {
        case .equalTo(let value):
            return ("\(key) == %@", value)
        case .lessThan(let value):
            return ("\(key) < %@", value)
        case .greaterThan(let value):
            return ("\(key) > %@", value)
        }
    }
}

extension NSPredicate {
    convenience init(predicate: Predicate) {
        let formatted = predicate.formatted
        self.init(format: formatted.format, formatted.value)
    }
}
