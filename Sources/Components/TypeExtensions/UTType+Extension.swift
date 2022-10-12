// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

import UniformTypeIdentifiers

enum UTTypeError: Error {
    case unsupportedFileType
}

extension UTType {
    func fileNameExtension() throws -> String {
        switch self {
        case .png, .image:
            return "png"
        case .jpeg:
            return "jpeg"
        default: throw UTTypeError.unsupportedFileType
        }
    }
}
