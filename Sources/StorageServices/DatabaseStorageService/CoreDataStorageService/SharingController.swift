// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import CloudKit
import UIKit
import os.log
import CoreData
import Network

@MainActor
class SharingController: NSObject, ObservableObject {

    typealias ShareMetadata = (container: CKContainer, share: CKShare)
    typealias SendableShareMetadata = SendableBox<ShareMetadata>

    @Published var shareState: ShareState<ShareMetadata> = .notYetShared
    @Published var isOnline = false
    private var networkMonitor: NWPathMonitor?
    private let networkQueue = DispatchQueue(label: "Monitor")
    private let databaseStorageService: DatabaseStorageService
    private var systemSharingObserver: CKSystemSharingUIObserver?

    let projectID: ProjectID

    init(projectID: ProjectID, databaseStorageService: DatabaseStorageService) {
        self.projectID = projectID
        self.databaseStorageService = databaseStorageService
    }

    nonisolated func iCloudContainerAvailable() -> Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    func monitorNetworkConnection() {
        let networkMonitor = NWPathMonitor()
        networkMonitor.pathUpdateHandler = { [weak self] path in
            if let self {
                Task { @MainActor in
                    self.isOnline = path.status == .satisfied
                }
            }
        }
        networkMonitor.start(queue: networkQueue)
        self.networkMonitor = networkMonitor
    }

    func stopMonitoringNetworkConnection() {
        guard let networkMonitor else {
            return
        }
        networkMonitor.cancel()
        self.networkMonitor = nil
    }

    func presentCloudSharingController() {
        var shareMetadata: ShareMetadata?
        // Get share metadata if exists
        if case .shared(let existingShareMetadata, _) = shareState {
            shareMetadata = existingShareMetadata
        }
        // .pending share state turns share button into a spinner so it cannot be retapped while UICSC is being created
        shareState = .pending
        Task {
            if let shareMetadata {
                presentControllerForExistingShare(shareMetadata: shareMetadata)
            } else {
                presentControllerForNewShare()
            }
        }
    }

    /*
     Called when CloudSharingView resigns to update cloudSharingControllerDidSaveShare is not
     ever being called. This function is called when that view resigns to update the local share info.
     */
    func fetchShareInformation() {
        guard iCloudContainerAvailable() else {
            shareState = .notSignedIn
            return
        }
        do {
            if let existingShare = try databaseStorageService.fetchShare(projectID: self.projectID) {
                let existingShareMetadata = (databaseStorageService.getCKContainer(), existingShare)
                Task { @MainActor [weak self] in
                    self?.shareState = .shared(existingShareMetadata, isOwner: existingShare.currentUserIsOwner)
                }
            }
        } catch {
            os_log(.error, "Could not fetch share information; project not found")
        }
    }
}

/// This is used to override warnings in cases where we are pretty sure it's safe to send this object.
struct SendableBox<T>: @unchecked Sendable {
    var contents: T
}

// MARK: - Private
private extension SharingController {
    /// On a dismiss call, a view controller dismisses any popovers it has presented. This function first checks that the popover is the sharing controller before dismissing.
    func dismissSharingController(sharingController: UICloudSharingController) {
        guard let rootController = UIApplication.shared.rootController(),
              rootController.presentedViewController == sharingController else {
            os_log(.error, "Could not find root view controller")
            return
        }
        rootController.dismiss(animated: true)
    }

    /// When CKSystemSharingUIObserver receives a save share notification, this function updates the share metadata to reflect that save or logs an error before dismissing the sharing controller.
    nonisolated func handleDidSaveShare(saveResult: Result<CKShare, Error>, sharingController: UICloudSharingController) {
        switch saveResult {
            case .success(let share):
                let updatedShareMetadata = (databaseStorageService.getCKContainer(), share)
                Task { @MainActor [weak self] in
                    self?.shareState = .shared(updatedShareMetadata, isOwner: share.currentUserIsOwner)
                }
            case .failure(let error):
                os_log(.error, "Error saving share: \(error.localizedDescription)")
        }
        Task { @MainActor [weak self] in
            self?.dismissSharingController(sharingController: sharingController)
        }
    }

    /// When CKSystemSharingUIObserver receives a stop sharing notification, this function updates the shareState to reflect that change or logs an error before dismissing the sharing controller.
    nonisolated func handleDidStopSharing(deleteResult: Result<Void, Error>, sharingController: UICloudSharingController) {
        switch deleteResult {
            case .success(_):
            Task { @MainActor [weak self] in
                self?.shareState = .notYetShared
            }
            case .failure(let error):
                os_log(.error, "Error deleting share: \(error.localizedDescription)")
        }
        Task { @MainActor [weak self] in
            self?.dismissSharingController(sharingController: sharingController)
        }
    }

    func presentSharingController(sharingController: UICloudSharingController, shareState: ShareState<ShareMetadata>) {
        guard let rootController = UIApplication.shared.rootController() else {
            os_log(.error, "Could not find root view controller")
            return
        }
        rootController.present(sharingController, animated: true) {
            self.shareState = shareState
        }
    }

    /// Returns and observer that listens for changes to the CKShare coming form the UICloudSharingController
    func createSystemSharingObserver(container: CKContainer, sharingController: UICloudSharingController) -> CKSystemSharingUIObserver {
        let sharingObserver = CKSystemSharingUIObserver(container: container)
        sharingObserver.systemSharingUIDidSaveShareBlock = { [weak self] _, saveResult in
            self?.handleDidSaveShare(saveResult: saveResult, sharingController: sharingController)
        }
        sharingObserver.systemSharingUIDidStopSharingBlock = { [weak self] _, deleteResult in
            self?.handleDidStopSharing(deleteResult: deleteResult, sharingController: sharingController)
        }
        return sharingObserver
    }

    /// This preparation handler is the code the UICloudSharingController calls to create a share when the user hits a share method, before the sending window (i.e., iMessage window) appears
    func preparationHandler(completion: @escaping (CKShare?, CKContainer?, Error?) -> Void) {
        Task {
            do {
                let shareMetadata = try await self.databaseStorageService.initiateNewShare(projectID: self.projectID).contents
                await MainActor.run { [weak self] in
                    self?.shareState = .shared(shareMetadata, isOwner: shareMetadata.share.currentUserIsOwner)
                }
                completion(shareMetadata.share, shareMetadata.container, nil)
            } catch {
                completion(nil, nil, error)
            }
        }
    }

    /// Creates a UICloudSharingController that is passed a preparation handler that initializes a new share when user attempts to send share to a new participant.
    func presentControllerForNewShare() {
        let cloudSharingController = UICloudSharingController { [weak self] _, completion in
            self?.preparationHandler(completion: completion)
        }
        cloudSharingController.availablePermissions = [.allowReadWrite, .allowPrivate]
        cloudSharingController.modalPresentationStyle = .formSheet
        systemSharingObserver = createSystemSharingObserver(container: databaseStorageService.getCKContainer(), sharingController: cloudSharingController)
        presentSharingController(sharingController: cloudSharingController, shareState: .notYetShared)
    }

    /// Creates a UICloudSharingController using existing share metadata
    func presentControllerForExistingShare(shareMetadata: ShareMetadata) {
        let cloudSharingController = UICloudSharingController(share: shareMetadata.share, container: shareMetadata.container)
        cloudSharingController.availablePermissions = [.allowReadWrite, .allowPrivate]
        cloudSharingController.modalPresentationStyle = .formSheet
        systemSharingObserver = createSystemSharingObserver(container: databaseStorageService.getCKContainer(), sharingController: cloudSharingController)
        presentSharingController(sharingController: cloudSharingController, shareState: .shared(shareMetadata, isOwner: shareMetadata.share.currentUserIsOwner))
    }
}

private extension UIApplication {
    func rootController() -> UIViewController? {
        let scene = UIApplication.shared
             .connectedScenes
             .compactMap { $0 as? UIWindowScene }
             .first(where: { $0.keyWindow != nil })

        return scene?.keyWindow?.rootViewController
    }
}

extension CKShare {
    // Are we the owner
    var currentUserIsOwner: Bool {
        owner == currentUserParticipant
    }
}
