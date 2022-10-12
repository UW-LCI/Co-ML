// Copyright 2026 Apple Inc. All rights reserved.

import CoreData
import Foundation
import os.log

/// A wrapper for NSPersistentHistoryToken that stores it to disk so it can be read in the next session
struct PersistentToken {
    /**
     The file URL for persisting the persistent history token.
     */
    private let storageURL: URL

    init(url: URL) {
        storageURL = url
        token = Self.read(url: storageURL)
    }

    var token: NSPersistentHistoryToken? {
        didSet {
            guard token != oldValue else {
                return
            }
            guard let token else {
                Self.delete(url: storageURL)
                return
            }
            Self.write(url: storageURL, token: token)
        }
    }

    /// Delete an NSPersistentHistoryToken from disk if we no longer have a valid one to save
    private static func delete(url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                os_log(.info, "Failed to delete NSPersistentHistoryToken at \(url). \(error)")
            }
        }
    }

    /// Read an archived NSPersistentHistoryToken from disk if present
    private static func read(url: URL) -> NSPersistentHistoryToken? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            // It's fine for it not to be there - it's new or we erased it
            return nil
        }
        do {
            let tokenData = try Data(contentsOf: url)
            do {
                return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: tokenData)
            } catch {
                os_log(.default, "Failed to find NSPersistentHistoryToken at \(url). \(error)")
            }
        } catch {
            os_log(.default, "Failed to unarchive NSPersistentHistoryToken at \(url). \(error)")
        }
        return nil
    }

    /// Write an archived NSPersistentHistoryToken to disk if available
    private static func write(url: URL, token: NSPersistentHistoryToken) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
            try data.write(to: url)
        } catch {
            os_log(.info, "Failed to write NSPersistentHistoryToken at \(url). \(error)")
        }
    }
}

extension PersistentToken {

    /// Calculate and write to a path to store the token
    private static func tokenURL(directory: URL, storeID: String) -> URL {
        let url = directory
            .appending(path: "CK_History", directoryHint: .isDirectory)
            .appending(path: storeID, directoryHint: .isDirectory)

        do {
            let fileManager = FileManager.default
            try fileManager.createFolderIfNotPresent(folderURL: url)
        } catch {
            fatalError("Failed to create persistent container history directory at \(url). Error = \(error)")
        }

        return url.appending(path: "token.data", directoryHint: .notDirectory)
    }

    init(directory: URL, storeID: String) {
        self = .init(url: Self.tokenURL(directory: directory, storeID: storeID))
    }

    /// Use any old string identifier for this token.  Use one per store (private/shared)
    init(identifier: String) {
        self = .init(directory: NSPersistentContainer.defaultDirectoryURL(), storeID: identifier)
    }
}
