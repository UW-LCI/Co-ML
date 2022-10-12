// Copyright 2026 Apple Inc. All rights reserved.

/// CloudKit Sharing has some async initialization requirements.
/// ShareState tracks the acquisition of the sharing token and is used to control the display and behaviour of the sharing button and sheet.
///
/// Parameter T is the sharing token `SharingController.ShareMetadata`, or `Void` for testing.
enum ShareState<T> {
    /// the initial state of sharing before a project is first shared
    case notYetShared
    /// we are waiting for CK to give us a share - don't press button again
    case pending
    /// we have already clicked share once this session
    /// - Parameter owned: we are the owner of this share
    case shared(T, isOwner: Bool)
    /// cannot share because iCloud is not signed in
    case notSignedIn

    /// isPending: The share button should be disabled to prevent double sharing
    ///
    /// Pending means we are already waiting on CloudKit to create a share zone.
    ///
    /// The client should disable the share button and avoid calling
    var isPending: Bool {
        if case .pending = self {
            return true
        }
        return false
    }

    /// Share is not acquired yet, client should initiate share via the SharingController
    ///
    /// * Note: client should wait until the state becomes shared before attempting to present the share sheet
    var isNotYetShared: Bool {
        if case .notYetShared = self {
            return true
        }
        return false
    }

    /// User is not signed into an iCloud account. Sharing not possible.
    var isNotSignedIn: Bool {
        if case .notSignedIn = self {
            return true
        }
        return false
    }
}
