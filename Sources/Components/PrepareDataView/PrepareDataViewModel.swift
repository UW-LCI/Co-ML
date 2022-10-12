// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log
import Combine
import SwiftUI

@MainActor
class PrepareDataViewModel: ObservableObject {
    enum ViewMode {
        case loading
        case grid
    }

    @Published var albumCoverViewStates: [LabelRibbonViewState] = []
    @Published var labelStats: [PrepareDataStatsRow] = []
    @Published var viewMode: ViewMode = .loading
    @Published var isShowingCannotTrainAlert = false
    let projectID: ProjectID
    private var nextLabelNumber = 1

    private let projectModelInfoRepository: ProjectModelInfoRepository
    private let imageRepository: ImageRepository
    private let imageFetchRepository: ImageFetchRepository

    init(projectID: ProjectID,
         projectModelInfoRepository: ProjectModelInfoRepository,
         imageRepository: ImageRepository,
         imageFetchRepository: ImageFetchRepository
    ) {
        self.projectID = projectID
        self.projectModelInfoRepository = projectModelInfoRepository
        self.imageRepository = imageRepository
        self.imageFetchRepository = imageFetchRepository
    }

    func monitorProjectChanges() async {
        os_log(.debug, "[Prepare] Start monitoring project changes.")
        await loadTrainingData()
        for await _ in NotificationCenter.default.notifications(projectID: projectID) {
            await loadTrainingData(switchToGridWhenDone: false)
        }
        os_log(.debug, "[Prepare] End monitoring project changes.")
    }

    func loadTrainingData(switchToGridWhenDone: Bool = true) async {
        let dt = await ContinuousClock().measure {
            do {
                let projectModelInfo = try await projectModelInfoRepository.fetchProjectModelInfo()

                var ribbonStates: [LabelRibbonViewState] = []
                var trainingRows: [PrepareDataStatsRow] = []

                for label in projectModelInfo.labels {
                    let sampleIDs = projectModelInfo.sampleIDsByLabelUUID[label.id.id] ?? []
                    let ribbonState = LabelRibbonViewState(
                        label: label,
                        imageList: sampleIDs,
                        imageCount: sampleIDs.count
                    )
                    ribbonStates.append(ribbonState)
                    trainingRows.append(PrepareDataStatsRow(label: label.labelString, count: sampleIDs.count))
                }

                withAnimation {
                    nextLabelNumber = ribbonStates.count + 1
                    self.albumCoverViewStates = ribbonStates
                    self.labelStats = trainingRows
                    if switchToGridWhenDone {
                        viewMode = .grid
                    }
                }

            } catch let e {
                os_log(.error, "An error occurred: \(e)")
            }
        }

        os_log(.debug, "[Prepare] Load training data complete after \(dt).")
    }

    func switchToGridView() {
        viewMode = .grid
    }

    /// Returns the label ID of the created label
    func createNewLabel() -> LabelID {

        let newLabelString = "Label \(nextLabelNumber)"
        let newLabel = LabelAnnotation(label: newLabelString, projectID: projectID)

        Task(priority: .userInitiated) {
            do {
                // Then, add it to the image repository.
                try await imageRepository.add(label: newLabel)

            } catch let e as SampleStorageServiceError {
                fatalError("Unhandled SampleStorageServiceError: \(e)")
            } catch let e {
                fatalError("Unhandled Error: \(e)")
            }
        }

        return newLabel.id
    }

    func fetchImage(_ sampleID: UUID) async throws -> UIImage {
        try await imageFetchRepository.fetchImage(sampleUUID: sampleID)
    }
}

#if DEBUG

extension PrepareDataViewModel {

    /// a fake model to use in previews
    static var fake = PrepareDataViewModel(
        projectID: .fakeProjectID,
        projectModelInfoRepository: ProjectModelInfoRepositoryFake(projectID: .fakeProjectID),
        imageRepository: ImageRepositoryFake(projectID: .fakeProjectID),
        imageFetchRepository: ImageFetchRepositoryFake()
    )
}

#endif
