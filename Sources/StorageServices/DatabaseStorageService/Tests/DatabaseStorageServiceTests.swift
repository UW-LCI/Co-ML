// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
import CoreData
import UniformTypeIdentifiers
@testable import CoMLApp

final class DatabaseStorageServiceTests: XCTestCase {

    var coreDataStack: CoreDataStack!
    var coreDataDatabaseStorageService: CoreDataDatabaseStorageService!
    var databaseStorageService: DatabaseStorageService!

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStackFake()
        coreDataDatabaseStorageService = CoreDataDatabaseStorageService(coreDataStack: coreDataStack)
        databaseStorageService = coreDataDatabaseStorageService
    }

    override func tearDown() {
        databaseStorageService = nil
        coreDataDatabaseStorageService = nil
        coreDataStack = nil
        super.tearDown()
    }

    override func invokeTest() {
        for _ in 1...15 {
            super.invokeTest()
        }
    }

    func testCreateProject() async throws {

        let projects0 = try await databaseStorageService.fetchProjects()
        XCTAssertTrue(projects0.isEmpty)

        let projectID = UUID()
        let project = Project(id: projectID, title: "Test Project", createdAt: Date())
        try await databaseStorageService.create(project: project)

        let projects1 = try await databaseStorageService.fetchProjects()
        XCTAssertFalse(projects1.isEmpty)
        let project1 = projects1.first!
        XCTAssertEqual(project1.id, projectID)

        let projectLabels = try await databaseStorageService.fetchLabels(projectID: projectID)
        XCTAssertEqual(projectLabels.count, 2)

        XCTAssertEqual(projectLabels[0].labelString, "Label 1")
        XCTAssertEqual(projectLabels[1].labelString, "Label 2")
    }

    func testAddedLabelsAreSortedByCreationDateAscending() async throws {
        // First, create a project for the labels to be attached to.
        let projectID = UUID()
        let project = Project(id: projectID, title: "Test Project", createdAt: Date())
        try await databaseStorageService.create(project: project)

        // Then, create a Truck label associated with that project.
        let truckAnnotation = LabelAnnotation(label: "Truck", projectID: projectID)
        try await databaseStorageService.add(label: truckAnnotation)

        // Then, create a Sun label after a delay.
        try await Task.sleep(milliseconds: 5)
        let sunAnnotation = LabelAnnotation(label: "Sun", projectID: projectID)
        try await databaseStorageService.add(label: sunAnnotation)

        // Then a Moon label.
        try await Task.sleep(milliseconds: 5)
        let moonAnnotation = LabelAnnotation(label: "Moon", projectID: projectID)
        try await databaseStorageService.add(label: moonAnnotation)

        // Then, fetch the labels and assert they are sorted as expected.
        let labels = try await databaseStorageService.fetchLabels(projectID: projectID)
        XCTAssertEqual(labels.count, 5)
        XCTAssertEqual(labels[2].labelString, "Truck")
        XCTAssertEqual(labels[3].labelString, "Sun")
        XCTAssertEqual(labels[4].labelString, "Moon")

        // Note: The above labels are currently added on _top of_ the default labels.
    }

    func testLabelRename() async throws {
        let projectID = UUID()
        let project = Project(id: projectID, title: "Test Project", createdAt: Date())
        try await databaseStorageService.create(project: project)

        let truckAnnotationMisspelled = LabelAnnotation(label: "Truc", projectID: projectID)
        try await databaseStorageService.add(label: truckAnnotationMisspelled)

        // Correct the spelling of the label.
        try await databaseStorageService.update(labelWithID: truckAnnotationMisspelled.id, newLabelString: "Truck")

        // Then, fetch the labels and assert they are sorted as expected.
        let labels = try await databaseStorageService.fetchLabels(projectID: projectID)
        XCTAssertEqual(labels.count, 3)
        XCTAssertEqual(labels.last!.labelString, "Truck")
    }

    func testCreatedSamplesAreSortedByCreationDateAscending() async throws {
        // First, create a project for the sample to be attached to.
        let projectID = UUID()
        let project = Project(id: projectID, title: "Test Project", createdAt: Date())
        try await databaseStorageService.create(project: project)

        // Then, create a Truck label associated with that project.
        let truckAnnotation = LabelAnnotation(label: "Truck", projectID: projectID)
        try await databaseStorageService.add(label: truckAnnotation)

        // Then, create a Sun label after a delay.
        try await Task.sleep(milliseconds: 5)
        let sunAnnotation = LabelAnnotation(label: "Sun", projectID: projectID)
        try await databaseStorageService.add(label: sunAnnotation)

        // Then a Moon label.
        try await Task.sleep(milliseconds: 5)
        let moonAnnotation = LabelAnnotation(label: "Moon", projectID: projectID)
        try await databaseStorageService.add(label: moonAnnotation)

        // Then, create a sample for the Truck label.
        try await Task.sleep(milliseconds: 5)
        let truckImage = UIImage(systemName: "box.truck")!
        let truckLabeledImage = LabeledImage(image: truckImage, labelID: truckAnnotation.id)
        try await databaseStorageService.add(labeledImage: truckLabeledImage)

        // And another truck.
        try await Task.sleep(milliseconds: 5)
        let truckImage2 = UIImage(systemName: "box.truck.fill")!
        let truckLabeledImage2 = LabeledImage(image: truckImage2, labelID: truckAnnotation.id)
        try await databaseStorageService.add(labeledImage: truckLabeledImage2)

        // And add a Sun.
        try await Task.sleep(milliseconds: 5)
        let sunImage = UIImage(systemName: "sun.max")!
        let sunLabeledImage = LabeledImage(image: sunImage, labelID: sunAnnotation.id)
        try await databaseStorageService.add(labeledImage: sunLabeledImage)

        // Ensure there are 2 truck samples.
        let truckSamples = try await databaseStorageService.fetchSamples(labelID: truckAnnotation.id, dataType: .training)
        XCTAssertEqual(truckSamples.count, 2)

        // And 1 sun sample.
        let sunSamples = try await databaseStorageService.fetchSamples(labelID: sunAnnotation.id, dataType: .training)
        XCTAssertEqual(sunSamples.count, 1)

        // And 0 moons.
        let moonSamples = try await databaseStorageService.fetchSamples(labelID: moonAnnotation.id, dataType: .training)
        XCTAssertTrue(moonSamples.isEmpty)
    }

    func testCreatedSamplesCanBeIndividuallyFetched() async throws {
        // First, create a project for the sample to be attached to.
        let projectID = UUID()
        let project = Project(id: projectID, title: "Test Project", createdAt: Date())
        try await databaseStorageService.create(project: project)

        // Then, create a Truck label associated with that project.
        let truckAnnotation = LabelAnnotation(label: "Truck", projectID: projectID)
        try await databaseStorageService.add(label: truckAnnotation)

        // Then, create a sample for the Truck label.
        try await Task.sleep(milliseconds: 5)
        let truckImage = UIImage(systemName: "box.truck")!
        let truckLabeledImage = LabeledImage(image: truckImage, labelID: truckAnnotation.id)
        try await databaseStorageService.add(labeledImage: truckLabeledImage)

        // Then, FETCH the same sample back!
        let sampleID = truckLabeledImage.sampleID
        let fetchedSample = try databaseStorageService.fetchSample(sampleID: sampleID)

        // Make sure it is not nil, and make sure it is associated with the expected entities.
        XCTAssertEqual(fetchedSample.annotation.id, truckAnnotation.id)

        // This check is redundant since labelID equality implies projectID equality, but
        // let's include it for clarity.
        XCTAssertEqual(fetchedSample.annotation.projectID, projectID)
    }

    func testCreatedSamplesCanBeIndividuallyDeleted() async throws {
        // First, create a project for the sample to be attached to.
        let projectID = UUID()
        let project = Project(id: projectID, title: "Test Project", createdAt: Date())
        try await databaseStorageService.create(project: project)

        // Then, create a Truck label associated with that project.
        let truckAnnotation = LabelAnnotation(label: "Truck", projectID: projectID)
        try await databaseStorageService.add(label: truckAnnotation)

        // Then, create a sample for the Truck label.
        try await Task.sleep(milliseconds: 5)
        let truckImage = UIImage(systemName: "box.truck")!
        let truckLabeledImage = LabeledImage(image: truckImage, labelID: truckAnnotation.id)
        try await databaseStorageService.add(labeledImage: truckLabeledImage)

        // Then, FETCH the same sample back!
        let sampleID = truckLabeledImage.sampleID
        let fetchedSample = try databaseStorageService.fetchSample(sampleID: sampleID)

        // Only assert is is non-nil because we tested its content in another test.
        XCTAssertNotNil(fetchedSample)

        // Then, DELETE that sample, and fetch again.
        try await databaseStorageService.deleteSample(sampleID: sampleID)
        do {
            _ = try databaseStorageService.fetchSample(sampleID: sampleID)
        } catch {
            if case let DatabaseStorageServiceError.sampleNotFound(missingSampleID) = error {
                XCTAssertEqual(missingSampleID, sampleID)
                return
            }
            XCTFail("Unexpected error thrown: \(error)")
        }
        XCTFail("Should throw")
    }

    func testSamplesCanBeMovedBetweenLabels() async throws {
        // First, create a project for the sample to be attached to.
        let projectID = UUID()
        let project = Project(id: projectID, title: "Test Project", createdAt: Date())
        try await databaseStorageService.create(project: project)

        // Then, create a Truck label associated with that project.
        let truckAnnotation = LabelAnnotation(label: "Truck", projectID: projectID)
        try await databaseStorageService.add(label: truckAnnotation)

        // Then, create a Sun label after a delay.
        try await Task.sleep(milliseconds: 5)
        let sunAnnotation = LabelAnnotation(label: "Sun", projectID: projectID)
        try await databaseStorageService.add(label: sunAnnotation)

        // Then, create a sample for the Truck label, but add it to the wrong label.
        try await Task.sleep(milliseconds: 5)
        let truckImage = UIImage(systemName: "box.truck")!
        // Note below, we are using the "Sun" label ID.
        let truckLabeledImage = LabeledImage(image: truckImage, labelID: sunAnnotation.id)
        try await databaseStorageService.add(labeledImage: truckLabeledImage)

        // Fetch and assert label membership.
        let sampleID = truckLabeledImage.sampleID
        let fetchedSample = try databaseStorageService.fetchSample(sampleID: sampleID)
        XCTAssertNotNil(fetchedSample)
        XCTAssertEqual(fetchedSample.annotation.id, sunAnnotation.id)

        // Also check from the label direction.
        let sunSamples = try await databaseStorageService.fetchSamples(labelID: sunAnnotation.id, dataType: .training)
        let truckSamples = try await databaseStorageService.fetchSamples(labelID: truckAnnotation.id, dataType: .training)
        XCTAssertFalse(sunSamples.isEmpty)
        XCTAssertTrue(truckSamples.isEmpty)

        // Then move the sample to the correct label, and fetch again.
        try await databaseStorageService.moveSample(sampleID: sampleID, toLabelWithID: truckAnnotation.id)
        let fetchedAfterMove = try databaseStorageService.fetchSample(sampleID: sampleID)
        XCTAssertNotNil(fetchedAfterMove)
        XCTAssertEqual(fetchedAfterMove.annotation.id, truckAnnotation.id)

        // Also check from the label direction.
        let sunSamplesAfterMove = try await databaseStorageService.fetchSamples(labelID: sunAnnotation.id, dataType: .training)
        let truckSamplesAfterMove = try await databaseStorageService.fetchSamples(labelID: truckAnnotation.id, dataType: .training)
        XCTAssertTrue(sunSamplesAfterMove.isEmpty)
        XCTAssertFalse(truckSamplesAfterMove.isEmpty)
    }

    func testFetchProjectTitleYieldsCorrectTitle() async throws {
        let projectID = UUID()
        let project = Project(id: projectID, title: "Test Project", createdAt: Date())
        try await databaseStorageService.create(project: project)

        let fetchedTitle = try await databaseStorageService.fetchProjectTitle(id: projectID)
        XCTAssertEqual(fetchedTitle, "Test Project")
    }

    func testDeleteProjectRemovesProjectOnSubsequentFetch() async throws {
        let projectID = UUID()
        let project = Project(id: projectID, title: "Test Project", createdAt: Date())
        try await databaseStorageService.create(project: project)

        let fetchedProjects = try await databaseStorageService.fetchProjects()
        XCTAssertEqual(fetchedProjects.count, 1)

        try await databaseStorageService.delete(projectID: projectID, isOnline: true)

        let fetchedProjectsAfterDelete = try await databaseStorageService.fetchProjects()
        XCTAssertEqual(fetchedProjectsAfterDelete.count, 0)
    }

    func testRenameProjectUpdatesNameAsExpected() async throws {
        let projectID = UUID()
        let project = Project(id: projectID, title: "Test Project", createdAt: Date())
        try await databaseStorageService.create(project: project)

        let projectName = try await databaseStorageService.fetchProjectTitle(id: projectID)
        XCTAssertEqual(projectName, "Test Project")

        try await databaseStorageService.renameProject(id: projectID, newName: "Cheese")
        let renamedName = try await databaseStorageService.fetchProjectTitle(id: projectID)

        XCTAssertEqual(renamedName, "Cheese")
    }

    func testFetchProjectMetadataYieldsExpectedProperties() async throws {
        let projectID = UUID()
        let createdAt = Date()
        let project = Project(id: projectID, title: "Test Project", createdAt: createdAt)
        try await databaseStorageService.create(project: project)

        let fetchedProject = try await databaseStorageService.fetchProject(projectID: projectID)
        XCTAssertEqual(fetchedProject.id, projectID)
        XCTAssertEqual(fetchedProject.title, "Test Project")

        // There seems to be some kind of date inaccuracy in the database. But, the createdAt date is
        // _extremely close_ to the set date, just not exactly equal.
        let timeInterval = createdAt.timeIntervalSince(fetchedProject.createdAt)
        // They seem to be reliably of by approximately 0.001 seconds. 0.1 is enough to assert.
        XCTAssertLessThan(timeInterval, 0.1)
        XCTAssertFalse(fetchedProject.isShared)
        XCTAssertEqual(fetchedProject.labelNames.count, 2)
    }

    func testDeletingProjectLabelReturnsProjectToInitialLabels() async throws {
        let projectID = UUID()
        let createdAt = Date()
        let project = Project(id: projectID, title: "Test Project", createdAt: createdAt)
        try await databaseStorageService.create(project: project)

        let label = LabelAnnotation(label: "New Label", projectID: projectID)
        let labelID = label.id
        try await databaseStorageService.add(label: label)

        let fetchedProject = try await databaseStorageService.fetchProject(projectID: projectID)
        XCTAssertEqual(fetchedProject.labelNames.count, 3)
        XCTAssertEqual(fetchedProject.labelNames.last, "New Label")

        try await databaseStorageService.deleteLabel(id: labelID)

        let fetchedAfterDelete = try await databaseStorageService.fetchProject(projectID: projectID)
        XCTAssertEqual(fetchedAfterDelete.labelNames.count, 2)
    }

    func testDeletingProjectLabelDeletesAssociatedImages() async throws {
        let projectID = UUID()
        let createdAt = Date()
        let project = Project(id: projectID, title: "Test Project", createdAt: createdAt)
        try await databaseStorageService.create(project: project)

        // Then, create a Truck label associated with that project.
        let truckLabel = LabelAnnotation(label: "Truck", projectID: projectID)
        let truckLabelID = truckLabel.id
        try await databaseStorageService.add(label: truckLabel)

        // Check that it initially has a sample count of 0.
        let initialTruckSampleCount = try await databaseStorageService.fetchLabelSampleCount(id: truckLabel.id)
        XCTAssertEqual(initialTruckSampleCount, 0)

        // Then, create a sample for the Truck label.
        try await Task.sleep(milliseconds: 5)
        let truckImage = UIImage(systemName: "box.truck")!
        let truckLabeledImage = LabeledImage(image: truckImage, labelID: truckLabel.id)
        try await databaseStorageService.add(labeledImage: truckLabeledImage)
        let truckImageID = truckLabeledImage.id.sampleID

        let truckImageAgain = try databaseStorageService.fetchSample(sampleID: truckImageID)

        XCTAssertNotNil(truckImageAgain, "Unexpectedly got truck label")

        try await databaseStorageService.deleteLabel(id: truckLabelID)

        do {
            let truckImageAgain = try databaseStorageService.fetchSample(sampleID: truckImageID)

            XCTAssertNil(truckImageAgain, "Unexpectedly got truck image after truck label deletion")

        } catch DatabaseStorageServiceError.sampleNotFound {
            // Hooray! it works
            print("Label Successfully Detected")
        } catch DatabaseStorageServiceError.sampleHasNoLabel {
            XCTFail("Unexpectedly returned sample with missing label")
        } catch {
            XCTFail("Unexpected error description \(error.localizedDescription) \(error)")
        }
    }

    func testFetchLabelSampleCountReturnsNumberOfAddedSamples() async throws {
        // First, create a project for the sample to be attached to.
        let projectID = UUID()
        let project = Project(id: projectID, title: "Test Project", createdAt: Date())
        try await databaseStorageService.create(project: project)

        // Then, create a Truck label associated with that project.
        let truckAnnotation = LabelAnnotation(label: "Truck", projectID: projectID)
        try await databaseStorageService.add(label: truckAnnotation)

        // Check that it initially has a sample count of 0.
        let initialTruckSampleCount = try await databaseStorageService.fetchLabelSampleCount(id: truckAnnotation.id)
        XCTAssertEqual(initialTruckSampleCount, 0)

        // Then, create a sample for the Truck label.
        try await Task.sleep(milliseconds: 5)
        let truckImage = UIImage(systemName: "box.truck")!
        let truckLabeledImage = LabeledImage(image: truckImage, labelID: truckAnnotation.id)
        try await databaseStorageService.add(labeledImage: truckLabeledImage)

        // Check afterwards that it has a sample count of 1.
        let finalTruckSampleCount = try await databaseStorageService.fetchLabelSampleCount(id: truckAnnotation.id)
        XCTAssertEqual(finalTruckSampleCount, 1)
    }

    func testFetchLabelSampleCountReturnsNumberOfAddedSamplesOfDatatype() async throws {
        // First, create a project for the sample to be attached to.
        let projectID = UUID()
        let project = Project(id: projectID, title: "Test Project", createdAt: Date())
        try await databaseStorageService.create(project: project)

        // Then, create a Truck label associated with that project.
        let truckAnnotation = LabelAnnotation(label: "Truck", projectID: projectID)
        try await databaseStorageService.add(label: truckAnnotation)

        // Check that it initially has a sample count of 0.
        let initialTruckSampleCount = try await databaseStorageService.fetchLabelSampleCount(id: truckAnnotation.id)
        XCTAssertEqual(initialTruckSampleCount, 0)

        // Then, create a sample for the Truck label.
        try await Task.sleep(milliseconds: 5)
        let truckImage = UIImage(systemName: "box.truck")!
        let truckLabeledImage = LabeledImage(image: truckImage, labelID: truckAnnotation.id, dataType: .testing)
        try await databaseStorageService.add(labeledImage: truckLabeledImage)

        // Check afterwards that it has a sample count of 1.
        let finalTruckSampleCount = try await databaseStorageService.fetchLabelSampleCount(id: truckAnnotation.id, dataType: .testing)
        XCTAssertEqual(finalTruckSampleCount, 1)

        let trainingTruckSampleCount = try await databaseStorageService.fetchLabelSampleCount(id: truckAnnotation.id, dataType: .training)
        XCTAssertEqual(trainingTruckSampleCount, 0)
    }

    func testFetchLabelMetadataYieldsExpectedResult() async throws {
        // First, create a project for the samples to be attached to.
        let projectID = UUID()
        let project = Project(id: projectID, title: "Test Project", createdAt: Date())
        try await databaseStorageService.create(project: project)

        let metadata = try await databaseStorageService.fetchLabelMetadata(projectID: projectID)
        XCTAssertEqual(metadata.count, 2)
    }

    func testFetchSamplesWithLimitYieldsExpectedCountOfSamples() async throws {
        // First, create a project for the samples to be attached to.
        let projectID = UUID()
        let project = Project(id: projectID, title: "Test Project", createdAt: Date())
        try await databaseStorageService.create(project: project)

        // Then, create a Truck label associated with that project.
        let truckAnnotation = LabelAnnotation(label: "Truck", projectID: projectID)
        try await databaseStorageService.add(label: truckAnnotation)

        // Check that it initially has 0 samples.
        let initialSamples = try await databaseStorageService.fetchSamples(labelID: truckAnnotation.id, dataType: .training)
        XCTAssertEqual(initialSamples.count, 0)

        // Then, add 17 samples to training. (It doesn't matter that the image data is the same for all of them)
        let truckImage = UIImage(systemName: "box.truck")!
        for _ in 0..<17 {
            let newLabeledImage = LabeledImage(image: truckImage,
                                               labelID: truckAnnotation.id,
                                               dataType: .training)
            try await databaseStorageService.add(labeledImage: newLabeledImage)
        }

        // Also add 13 samples to testing.
        for _ in 0..<13 {
            let newLabeledImage = LabeledImage(image: truckImage,
                                               labelID: truckAnnotation.id,
                                               dataType: .testing)
            try await databaseStorageService.add(labeledImage: newLabeledImage)
        }

        // Fetch again with a limit.
        let limitedSamples = try await databaseStorageService.fetchSamples(labelID: truckAnnotation.id, datatype: .training, limit: 7)
        XCTAssertEqual(limitedSamples.count, 7)
    }

    func testFetchProjectTileViewStates() async throws {
        // First, create a project for the samples to be attached to.
        let projectID = UUID()
        let project = Project(id: projectID, title: "Test Project", createdAt: Date())
        try await databaseStorageService.create(project: project)

        // Then, create a Truck label associated with that project.
        let truckAnnotation = LabelAnnotation(label: "Truck", projectID: projectID)
        try await databaseStorageService.add(label: truckAnnotation)

        // Gather sample IDs so we can verify they are included in the project tile view state.
        var sampleIDs: [UUID] = []

        // Add 17 samples to training. (It doesn't matter that the image data is the same for all of them)
        let truckImage = UIImage(systemName: "box.truck")!
        for _ in 0..<17 {
            let sampleID = UUID()
            sampleIDs.append(sampleID)
            let existingLabeledImageID = LabeledImageID(existingSampleID: sampleID, labelID: truckAnnotation.id)
            let newLabeledImage = LabeledImage(existingLabeledImageID: existingLabeledImageID,
                                               image: truckImage,
                                               creationDate: Date(),
                                               dataType: .training)
            try await databaseStorageService.add(labeledImage: newLabeledImage)
        }

        // Fetch all projects.
        let allProjectTileViewStates = try databaseStorageService.fetchProjectTileViewStates()

        XCTAssertEqual(allProjectTileViewStates.count, 1)

        let firstState = try XCTUnwrap(allProjectTileViewStates.first)
        XCTAssertEqual(firstState.totalSampleCount, 17)
        let thumbnailSampleIDs: [UUID] = firstState.thumbnails.compactMap {
            switch $0 {
            case .placeholder:
                return nil
            case .image(let uuid):
                return uuid
            }
        }

        // Note the expected sample IDs are expected in reverse chronological order (i.e., newest first).
        let expectedSampleIDs = Array(sampleIDs.reversed()[0..<8])
        XCTAssertEqual(thumbnailSampleIDs, expectedSampleIDs)
    }
}
