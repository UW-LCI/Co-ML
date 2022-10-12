// Copyright 2026 Apple Inc. All rights reserved.

import os.log
import UIKit

/// An observable view model allowing the sample detail sheet view to interface with its repository.
@MainActor
final class SampleDetailSheetViewModel: ObservableObject {
    private let sampleDetailRepository: SampleDetailRepository

    @Published var sampleDetails: SampleDetails?
    @Published var isShowingDeleteAlert = false
    @Published var isShowingMoveAlert = false

    /// - Parameters:
    ///      - fetch: Whether to automatically fetch.  Turn off for unit tests
    init(sampleDetailRepository: SampleDetailRepository, fetch: Bool = true) {
        self.sampleDetailRepository = sampleDetailRepository
        if fetch {
            fetchSampleDetails()
        }
    }

    func fetchSampleDetails() {
        Task(priority: .userInitiated) {
            do {
                sampleDetails = try await self.sampleDetailRepository.fetchSampleDetails()
            } catch {
                os_log(.error, "An error occurred fetching sample details: \(error)")
            }
        }
    }

    func updateSelectedLabel(labelID: LabelID) {
        optimisticallyUpdateSelectedLabel(labelID: labelID)
        asyncUpdateSelectedLabel(labelID: labelID)
    }

    var image: UIImage {
        guard let sampleDetails else {
            return UIImage()
        }
        return sampleDetails.image.image
    }

    var labels: [LabelAnnotation] {
        guard let sampleDetails else {
            return []
        }
        return sampleDetails.labels
    }

    var selectedLabelName: String {
        guard let sampleDetails else {
            return ""
        }
        guard let label = sampleDetails.labels.first(where: { $0.id == sampleDetails.selectedLabelID }) else {
            return ""
        }
        return label.labelString
    }

    func delete() async throws {
        sampleDetails = nil
        isShowingDeleteAlert = false
        try await self.sampleDetailRepository.deleteSample()
    }

    var currentDataTypeDescription: String {
        sampleDetailRepository.dataType.localizedDescription
    }

    var oppositeDataTypeDescription: String {
        sampleDetailRepository.dataType.oppositeDataType.localizedDescription
    }

    func moveToOppositeDataType() async throws {
        sampleDetails = nil
        isShowingMoveAlert = false
        try await sampleDetailRepository.moveToOppositeDataType()
    }

    var showToolbar: Bool {
        sampleDetails != nil
    }

    // MARK: - Private

    /// Optimistically updates the sample details so that the view hierarchy immediately shows the new selection.
    private func optimisticallyUpdateSelectedLabel(labelID: LabelID) {
        guard let originalSampleDetails = sampleDetails else {
            return
        }
        let originalImage = originalSampleDetails.image
        let newImage = LabeledImage(existingLabeledImage: originalImage, newLabelID: labelID)
        let newDetails = SampleDetails(image: newImage,
                                       labels: originalSampleDetails.labels,
                                       selectedLabelID: labelID)
        sampleDetails = newDetails
    }

    /// Tells the repository to make the same change.
    private func asyncUpdateSelectedLabel(labelID: LabelID) {
        Task {
            do {
                try await sampleDetailRepository.updateSelectedLabel(labelID: labelID)

            } catch let sampleDetailRepositoryError as SampleDetailRepositoryError {
                handle(sampleDetailRepositoryError: sampleDetailRepositoryError)

            } catch {
                os_log(.error, "An unexpected error occurred updating a sample's label: \(error)")
            }
        }
    }

    /// Handles a sample detail repository error, possibly triggering a sample details refresh.
    private func handle(sampleDetailRepositoryError: SampleDetailRepositoryError) {
        os_log(.error, "An error occurred updating a sample's label: \(sampleDetailRepositoryError)")

        if case let .failedToUpdateLabelID(labelID) = sampleDetailRepositoryError {
            os_log(.info, "Failed to update label ID to \(labelID)")
            fetchSampleDetails()
        }
    }
}

#if DEBUG

extension SampleDetailSheetViewModel {
    static var fake: Self {
        .init(sampleDetailRepository: .fake)
    }
}

#endif
