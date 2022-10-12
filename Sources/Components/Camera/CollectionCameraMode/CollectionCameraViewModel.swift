// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log
import SwiftUI

@MainActor
final class CollectionCameraViewModel: ObservableObject {

    @Published var settings: CameraSettings {
        didSet {
            os_log(.info, "Camera settings updated by user or otherwise: \(self.settings.debugDescription)")
        }
    }

    // camera view state

    @Published var showErrorAlert = false
    @Published private(set) var errorAlertText: String = ""

    // labels loaded into camera
    @Published private(set) var imageIDs: [LabeledImageID] = []
    @Published private(set) var annotationList: [LabelAnnotation] = []

    // data and services
    private let projectID: ProjectID
    private let projectModelInfoRepository: ProjectModelInfoRepository
    private let imageFetchRepository: ImageFetchRepository
    private let imageRepository: ImageRepository

    init(settings: CameraSettings,
         projectID: ProjectID,
         projectModelInfoRepository: ProjectModelInfoRepository,
         imageFetchRepository: ImageFetchRepository,
         imageRepository: ImageRepository
    ) {
        self.settings = settings
        self.projectID = projectID
        self.projectModelInfoRepository = projectModelInfoRepository
        self.imageFetchRepository = imageFetchRepository
        self.imageRepository = imageRepository
    }

    /// for displaying the label
    var labelString: String {
        settings.annotation?.labelString ?? "None"
    }

    var isTraining: Bool {
        settings.saveDestination == .training
    }

    /// Reloads the labels
    ///
    /// if the currently selected label is not one of the loaded labels, switch to the first available
    func loadLabels() async throws {

        let projectModelInfo = try await projectModelInfoRepository.fetchProjectModelInfo()
        annotationList = projectModelInfo.labels

        // If no label or an incorrect label is selected, pick a new one
        guard let annotation = settings.annotation,
           annotationList.contains(annotation) else {
            os_log(.info, "Existing label \(self.settings.annotation?.labelString ?? "<nil>") no longer exists, picking a new label: \(self.annotationList.first?.labelString ?? "<nil>")")
            self.settings.annotation = self.annotationList.first
            return
        }
    }

    func savePhoto(image: UIImage) async {
        // get the latest label
        guard let label = settings.annotation else {
            // Discard this photo, we insist on having a label!
            os_log(.default, "Tried to take a camera picture with no label selected")
            return
        }

        os_log(.info, "A photo was taken by the user for label '\(label)'")
        let labeledImage = LabeledImage(
            image: image,
            labelID: label.id,
            dataType: settings.saveDestination
        )

        showErrorAlert = false

        do {
            try await imageRepository.add(labeledImage: labeledImage)
        } catch let error {
            os_log(.error, "Failed to save photo to repository \(error)")
            errorAlertText = "Error: something went wrong saving your latest photo."
            showErrorAlert = true
        }
    }

    /// Observe updates from the database
    func observeDatabaseUpdates() async {
        os_log(.info, "Started listening for database image updates in CollectionCameraViewModel")

        let imageDatabaseUpdates = NotificationCenter.default.notifications(projectID: projectID)

        for await _ in imageDatabaseUpdates {
            await refreshImagesFromDatabase()
        }

        os_log(.info, "Done listening for database image updates in CollectionCameraViewModel")
    }

    func refreshImagesFromDatabase() async {
        do {
            let projectModelInfo = try await projectModelInfoRepository.fetchProjectModelInfo()

            guard let selectedLabel = settings.annotation else {
                os_log(.debug, "No label is selected so not showing any images.")
                self.imageIDs = []
                return
            }

            let lookupDictionary = settings.saveDestination == .training
                ? projectModelInfo.sampleIDsByLabelUUID
                : projectModelInfo.testSampleIDsByLabelUUID

            guard let sampleIDs = lookupDictionary[selectedLabel.id.id] else {
                os_log(.debug, "No samples for selected label \(selectedLabel), so not showing any images.")
                self.imageIDs = []
                return
            }

            // Only show the 8 most recent images in the stream.
            self.imageIDs = sampleIDs.prefix(8).map {
                LabeledImageID(existingSampleID: $0, labelID: selectedLabel.id)
            }

        } catch {
            os_log(.default, "Error fetching images from database for camera feed \(error)")
        }
    }

    func fetchImage(_ sampleID: UUID) async throws -> UIImage {
        try await imageFetchRepository.fetchImage(sampleUUID: sampleID)
    }
}
