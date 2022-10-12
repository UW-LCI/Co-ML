// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log

extension FileManager {
    func createFolderIfNotPresent(folderURL: URL, debugCallerLabel: String = #function) throws {
        guard !fileExists(atPath: folderURL.path) else {
            return
        }
        os_log(.info, """
            Creating folder at "\(folderURL.path) for \(debugCallerLabel)"
        """)
        try createDirectory(
            at: folderURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}
