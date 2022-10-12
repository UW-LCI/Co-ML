// Copyright 2026 Apple Inc. All rights reserved.

import Combine
import Foundation
import os.log
import UIKit

@MainActor
class LabelDetailViewModel: ObservableObject {

    /// Used for label editing.
    @Published var imageCount = 0
    let projectID: ProjectID

    @Published private(set) var labelExists = true

    @Published private(set) var imageIDs: [LabeledImageID] = []
    let openSampleDetail: (_: LabeledImageID) -> Void

    // FIXME: Figure out details about how this might change
    @Published private(set) var labelAnnotation: LabelAnnotation
    let dataType: DataType
    private let openPhotos: (PhotoPickerSettings) -> Void

    private let imageStorageService: ImageStorageService
    private let labelDetailRepository: LabelDetailRepository
    private let imageFetchRepository: ImageFetchRepository
    private let databaseStorageService: DatabaseStorageService

    init(labelAnnotation: LabelAnnotation,
         dataType: DataType,
         projectID: ProjectID,
         imageStorageService: ImageStorageService,
         labelDetailRepository: LabelDetailRepository,
         imageFetchRepository: ImageFetchRepository,
         databaseStorageService: DatabaseStorageService,
         openPhotosPicker: @escaping (PhotoPickerSettings) -> Void,
         openSampleDetail: @escaping (LabeledImageID) -> Void) {
        self.labelAnnotation = labelAnnotation
        self.dataType = dataType
        self.projectID = projectID
        self.openPhotos = openPhotosPicker
        self.openSampleDetail = openSampleDetail

        // Configure services.
        self.imageStorageService = imageStorageService
        self.labelDetailRepository = labelDetailRepository
        self.databaseStorageService = databaseStorageService
        self.imageFetchRepository = imageFetchRepository
    }

    /// to be called by view
    func openPhotosPicker() {
        openPhotos(PhotoPickerSettings(saveDestination: dataType, label: labelAnnotation))
    }

    func monitorProjectChanges() async {
        // Start with an initial image refresh.
        await refreshImageIDs()

        // Then refresh whenever the project changes.
        for await _ in NotificationCenter.default.notifications(projectID: projectID) {

            await refreshLabel()
            await refreshImageIDs()
        }
    }

    func update(label: String) {
        os_log(.info, "Updating label \(self.labelAnnotation) string to \(label).")
        Task(priority: .userInitiated) { @MainActor in
            do {
                try await imageStorageService.update(labelWithID: labelAnnotation.id, newLabelString: label)
                self.labelAnnotation = LabelAnnotation(existingAnnotation: self.labelAnnotation,
                                                       updatedString: label)
            } catch {
                os_log(.error, "An error occurred updating the label: \(error)")
            }
        }
    }

    func fetchImage(_ sampleID: UUID) async throws -> UIImage {
        try await imageFetchRepository.fetchImage(sampleUUID: sampleID)
    }

    /// to be called by view
    static func cameraRoute(label: LabelAnnotation, dataType: DataType) -> ProjectFullScreenRoute {
        let settings = CameraSettings(annotation: label, saveDestination: dataType, viewMode: .collectionMode)
        return ProjectFullScreenRoute.cameraPage(projectID: label.projectID,
                                                 settings: settings)
    }
}

// MARK: - Private

private extension LabelDetailViewModel {

    func refreshImageIDs() async {
        do {
            imageIDs = try await labelDetailRepository.fetchImageIDs()
            imageCount = imageIDs.count

        } catch {
            os_log(.error, "An error occurred refreshing images: \(error)")
            if error.isLabelUnavailableError(matching: labelAnnotation) {
                labelExists = false
            }
        }
    }

    func refreshLabel() async {
        do {
            if let label = try await databaseStorageService.fetchLabel(labelID: labelAnnotation.id) {
                self.labelAnnotation = label
            } else {
                os_log(.error, "Label fetch for \(self.labelAnnotation.idString) returned nil!")
            }
        } catch {
            os_log(.error, "An error occurred fetching label \(self.labelAnnotation.idString)")
        }
    }
}

private extension Error {
    func isLabelUnavailableError(matching annotation: LabelAnnotation) -> Bool {
        guard let databaseStorageServiceError = self as? DatabaseStorageServiceError else {
            return false
        }
        return databaseStorageServiceError.isLabelUnavailableError(matching: annotation)
    }
}

private extension DatabaseStorageServiceError {
    func isLabelUnavailableError(matching annotation: LabelAnnotation) -> Bool {
        switch self {
        case .labelNotFound(let labelID):
            return labelID == annotation.id

        case .labelUnavailable(let uuidString):
            // This case shouldn't exist, but let's support it for now.
            return uuidString == annotation.idString

        case .projectNotFound(let projectID):
            // If the whole project is not found, the label is also unavailable!
            return projectID == annotation.projectID

        case .invalidSamples, .sampleNotFound, .sampleHasNoLabel, .notAvailable, .cantBatchAddToMultipleLabels:
            return false
        }
    }
}
