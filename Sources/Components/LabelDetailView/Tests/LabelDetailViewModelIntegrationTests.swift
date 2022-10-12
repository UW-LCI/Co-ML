// Copyright 2026 Apple Inc. All rights reserved.

import Combine
import Foundation
@testable import CoMLApp
import XCTest

@MainActor
final class LabelDetailViewModelIntegrationTests: XCTestCase {

    let initialImageCount = 239
    var project: Project!
    var labelAnnotation: LabelAnnotation!
    var coreDataStack: CoreDataStack!
    var databaseStorageService: DatabaseStorageService!
    var sampleStorageService: SampleStorageService!
    var imageStorageService: ImageStorageService!
    var projectModelInfoRepository: ProjectModelInfoRepository!
    var imageFetchRepository: ImageFetchRepository!
    var labelDetailRepository: LabelDetailRepository!

    var viewModel: LabelDetailViewModel!

    override func setUp() async throws {
        try await super.setUp()

        project = Project(id: .fakeProjectID, title: "Fruits and Vegetables", createdAt: Date())

        labelAnnotation = LabelAnnotation(label: "Apples", projectID: .fakeProjectID)
        coreDataStack = CoreDataStackFake() // In-memory database instead of on disk; we don't need to "tearDown"
        databaseStorageService = CoreDataDatabaseStorageService(coreDataStack: coreDataStack)

        try await databaseStorageService.create(project: project)
        try await databaseStorageService.add(label: labelAnnotation)
        for _ in 0..<initialImageCount {
            let image = LabeledImage(image: UIImage(systemName: "apple.logo")!, labelID: labelAnnotation.id)
            try await databaseStorageService.add(labeledImage: image)
        }

        sampleStorageService = SampleStorageServiceImpl(databaseStorageService: databaseStorageService)
        imageStorageService = ImageStorageServiceImpl(sampleStorageService: sampleStorageService)
        projectModelInfoRepository = ProjectModelInfoRepositoryImpl(projectID: .fakeProjectID, databaseStorageService: databaseStorageService)
        imageFetchRepository = ImageFetchRepositoryFake()
        labelDetailRepository = LabelDetailRepositoryImpl(labelID: labelAnnotation.id,
                                                          dataType: .training,
                                                          projectModelInfoRepository: projectModelInfoRepository)

        viewModel = LabelDetailViewModel(
            labelAnnotation: labelAnnotation,
            dataType: .training,
            projectID: .fakeProjectID,
            imageStorageService: imageStorageService,
            labelDetailRepository: labelDetailRepository,
            imageFetchRepository: imageFetchRepository,
            databaseStorageService: databaseStorageService,
            openPhotosPicker: { photoPickerSettings in
                XCTFail("openPhotosPicker called \(photoPickerSettings)")
            },
            openSampleDetail: { labeledImageID in
                XCTFail("openSampleDetail called \(labeledImageID)")
            })
    }

    func testViewModelAutomaticallyRefreshesImagesWithRemoteImageAdded() async throws {
        let monitorTask = Task {
            await viewModel.monitorProjectChanges()
        }

        var imageIDsIterator = viewModel.$imageIDs.values.makeAsyncIterator()
        let initialImages = await imageIDsIterator.next()
        XCTAssertEqual(initialImages!.count, 0)
        let refreshedImages = await imageIDsIterator.next()
        XCTAssertEqual(refreshedImages!.count, initialImageCount)

        // Let's add an image to the database, and hopefully that will trigger an update.
        let numAddedImages = 113
        for _ in 0..<numAddedImages {
            let anotherImage = LabeledImage(image: UIImage(systemName: "appletv.fill")!, labelID: labelAnnotation.id)
            try await databaseStorageService.add(labeledImage: anotherImage)
        }

        // N.B. the absence of another `refreshImages()` call. The addition of the image itself should trigger the
        // notification observer to perform the refresh.
        var numUpdates = 0
        while true {
            let automaticallyRefreshedImages = await imageIDsIterator.next()
            XCTAssertGreaterThan(automaticallyRefreshedImages!.count, initialImageCount)
            numUpdates += 1
            if automaticallyRefreshedImages!.count == initialImageCount + numAddedImages {
                break
            }
        }

        XCTAssertLessThanOrEqual(numUpdates, numAddedImages)

        // Stop monitoring once the test is done.
        monitorTask.cancel()
    }
}
