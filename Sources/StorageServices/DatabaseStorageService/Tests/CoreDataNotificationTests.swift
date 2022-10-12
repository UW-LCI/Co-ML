// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
import CoreData
@testable import CoMLApp
import UniformTypeIdentifiers

final class CoreDataNotificationTests: XCTestCase {
    private var _maybeCoreDataStack: CoreDataStack?
    private var coreDataStack: CoreDataStack {
        return _maybeCoreDataStack!
    }
    override func setUpWithError() throws {
        try super.setUpWithError()
        _maybeCoreDataStack = CoreDataStackImpl(useCloudKit: false)
        sleep(1) ///clear notifications from setup and teardown
    }

    override func tearDownWithError() throws {
        let context = coreDataStack.persistentContainer.newBackgroundContext()
        try coreDataStack.context.performAndWait {
            let projectFetchRequest = SHSingleLabelClassifierProject.fetchRequest()
            let shProjects = try context.fetch(projectFetchRequest)
            for shProject in shProjects where shProject.title == "CoreDataNotificationTests: XCTest project" {
                context.delete(shProject)
                do {
                    try context.save()
                } catch let error {
                    XCTFail("Context save failed \(error)")
                }
            }
        }
        _maybeCoreDataStack = nil
        try super.tearDownWithError()
    }

    private func setExpectations(expectedProjectIds: [UUID]) {
        for id in expectedProjectIds {
            self.expectation(forNotification: .projectsUpdated,
                             object: nil) { notification in
                guard let receivedProjectIDs = notification.userInfo?[CoreDataStackImpl.CoreDataStrings.projectIDKey] as? Set<UUID> else {
                    XCTFail("Didn't get the user info I wanted. boo....")
                    return false
                }
                if receivedProjectIDs.contains(id) {
                    return true
                }
                return false
            }
        }
    }

    func testRemoteChangeNotifications() throws {
        for store in coreDataStack.persistentContainer.persistentStoreCoordinator.persistentStores {
            self.expectation(forNotification: .NSPersistentStoreRemoteChange,
                                               object: coreDataStack.persistentContainer.persistentStoreCoordinator) { notification in
                let identifier = notification.userInfo![NSStoreUUIDKey] as! String
                return identifier == store.identifier
            }
        }

        let context = coreDataStack.persistentContainer.newBackgroundContext()
        context.perform {
            for store in self.coreDataStack.persistentContainer.persistentStoreCoordinator.persistentStores {
                let project = SHSingleLabelClassifierProject(context: context)
                project.title = "CoreDataNotificationTests: XCTest project"
                project.id = UUID().uuidString
                project.creationDate = Date()

                context.assign(project, to: store)
            }
            do {
                try context.save()
            } catch let error {
                XCTFail("Context save failed \(error)")
            }
        }
        self.waitForExpectations(timeout: 10.0)
    }

    func testNotificationsEmittedForCorrectChangesInBothStores() throws {
        sleep(1) ///clear notifications from setup and teardown
        let uuids = [UUID(), UUID()]
        setExpectations(expectedProjectIds: uuids)

        let context = coreDataStack.persistentContainer.newBackgroundContext()

        context.perform {
            for (index, store) in self.coreDataStack.persistentContainer.persistentStoreCoordinator.persistentStores.enumerated() {
                let project = SHSingleLabelClassifierProject(context: context)
                project.title = "CoreDataNotificationTests: XCTest project"
                print(uuids[index].uuidString)
                project.id = uuids[index].uuidString
                project.creationDate = Date()

                context.assign(project, to: store)

                do {
                    try context.save()
                } catch let error {
                    XCTFail("Context save failed \(error)")
                }

                let newLabel = SHLabel(context: context)
                newLabel.creationDate = Date()
                newLabel.id = UUID().uuidString
                newLabel.labelString = "Test label"
                newLabel.project = project

                do {
                    try context.save()
                } catch let error {
                    XCTFail("Context save failed \(error)")
                }

                let newSample = SHSingleLabelSample(context: context)
                newSample.id = UUID().uuidString
                newSample.creationDate = Date.now
                newSample.label = newLabel
                newSample.sampleDataType = ""
                newSample.sampleData = Data()
                newSample.purpose = ""

                do {
                    try context.save()
                } catch let error {
                    XCTFail("Context save failed \(error)")
                }
            }
        }
        self.waitForExpectations(timeout: 10.0)
    }

    func testNotificationPayload() throws {
        sleep(1) ///clear notifications from setup and teardown
        let projectId = UUID()

        //test add project
        print("CHANGE ADD PROJECT")
        let context = coreDataStack.persistentContainer.newBackgroundContext()
        let project = testAddProjectNotification(projectId: projectId, context: context)
        XCTAssert(project.id == projectId.uuidString)
        XCTAssert(project.labels!.count < 1)

        //test add label
        print("CHANGE ADD LABEL")
        var label1 = testAddLabelNotification(to: project, context: context)
        XCTAssert(label1.labelString == "New Label")
        XCTAssert(label1.project == project)
        XCTAssert(project.labels!.count == 1)
        //swiftlint:disable:next empty_count
        XCTAssert(label1.samples!.count == 0)

        //test change label string
        print("CHANGE LABEL STRING")
        label1 = testChangeLabelNotification(projectId: projectId, label: label1, context: context)
        XCTAssert(label1.labelString == "Renamed Label 1")
        XCTAssert(label1.project == project)
        XCTAssert(project.labels!.count == 1)
        //swiftlint:disable:next empty_count
        XCTAssert(label1.samples!.count == 0)

        //test add image
        print("CHANGE ADD IMAGE")
        var image = testAddImageNotification(projectId: projectId, label: label1, context: context)
        XCTAssert(image.label == label1)
        XCTAssert(label1.samples!.count == 1)

        //add second label
        print("CHANGE ADD LABEL")
        let label2 = testAddLabelNotification(to: project, context: context)
        XCTAssert(label2.labelString == "New Label")
        XCTAssert(label2.project == project)
        XCTAssert(project.labels!.count == 2)
        //swiftlint:disable:next empty_count
        XCTAssert(label2.samples!.count == 0)
        XCTAssert(label1.samples!.count == 1)

        //test move image to label
        print("CHANGE MOVE IMAGE LABEL")
        image = testMoveImageLabelNotification(projectId: projectId, image: image, destinationLabel: label2, context: context)
        //swiftlint:disable:next empty_count
        XCTAssert(label1.samples!.count == 0)
        XCTAssert(label2.samples!.count == 1)

        //test move image to test
        print("CHANGE MOVE IMAGE PURPOSE")
        image = testMoveImageToTestNotification(projectId: projectId, image: image, context: context)
        XCTAssert(image.purpose == "testing")

        //test delete image
        print("CHANGE DELETE IMAGE")
        testDeleteImageNotification(projectId: projectId, image: image, context: context)
        //swiftlint:disable:next empty_count
        XCTAssert(label1.samples!.count == 0)
        //swiftlint:disable:next empty_count
        XCTAssert(label2.samples!.count == 0)

        //test delete label
        print("CHANGE DELETE LABEL")
        testDeleteLabelNotification(projectId: projectId, label: label2, context: context)
        //swiftlint:disable:next empty_count
        XCTAssert(project.labels!.count == 1)

        //test delete project
        print("CHANGE DELETE PROJECT")
        testDeleteProjectNotification(project: project, context: context)
    }

    private func testAddProjectNotification(projectId: UUID, context: NSManagedObjectContext) -> SHSingleLabelClassifierProject {
        var project: SHSingleLabelClassifierProject?
        setExpectations(expectedProjectIds: [projectId])
        context.perform {
            project = SHSingleLabelClassifierProject(context: context)
            project!.title = "CoreDataNotificationTests: XCTest project"
            project!.id = projectId.uuidString
            project!.creationDate = Date()

            context.assign(project!, to: self.coreDataStack.privatePersistentStore)

            do {
                try context.save()
            } catch let error {
                XCTFail("Context save failed \(error)")
            }
        }
        self.waitForExpectations(timeout: 3.0)
        return project!
    }

    private func testAddLabelNotification(to project: SHSingleLabelClassifierProject, context: NSManagedObjectContext, shouldSave: Bool = true) -> SHLabel {
        var label = SHLabel()
        setExpectations(expectedProjectIds: [UUID(uuidString: project.id!)!])
        context.perform {
            label = SHLabel(context: context)
            label.labelString = "New Label"
            label.id = UUID().uuidString
            label.creationDate = Date()
            label.project = project

            if shouldSave {
                do {
                    try context.save()
                } catch let error {
                    XCTFail("Context save failed \(error)")
                }
            }
        }
        if shouldSave {
            self.waitForExpectations(timeout: 3.0)
        }
        return label
    }

    private func testChangeLabelNotification(projectId: UUID, label: SHLabel, context: NSManagedObjectContext) -> SHLabel {
        setExpectations(expectedProjectIds: [projectId])
        context.perform {
            label.labelString = "Renamed Label 1"

            do {
                try context.save()
            } catch let error {
                XCTFail("Context save failed \(error)")
            }
        }
        self.waitForExpectations(timeout: 3.0)
        return label
    }

    private func testAddImageNotification(projectId: UUID, label: SHLabel, context: NSManagedObjectContext) -> SHSingleLabelSample {
        var image = SHSingleLabelSample()
        setExpectations(expectedProjectIds: [projectId])
        context.perform {
            image = SHSingleLabelSample(context: context)
            image.id = UUID().uuidString
            image.creationDate = .now
            image.purpose = DataType.training.purposeString
            image.sampleData = Data()
            image.sampleDataType = UTType.jpeg.identifier
            image.label = label

            do {
                try context.save()
            } catch let error {
                XCTFail("Context save failed \(error)")
            }
        }
        self.waitForExpectations(timeout: 3.0)
        return image
    }

    private func testMoveImageLabelNotification(projectId: UUID, image: SHSingleLabelSample, destinationLabel: SHLabel, context: NSManagedObjectContext) -> SHSingleLabelSample {
        setExpectations(expectedProjectIds: [projectId])
        context.perform {
            image.label = destinationLabel

            do {
                try context.save()
            } catch let error {
                XCTFail("Context save failed \(error)")
            }
        }
        self.waitForExpectations(timeout: 3.0)
        return image
    }

    private func testMoveImageToTestNotification(projectId: UUID, image: SHSingleLabelSample, context: NSManagedObjectContext) -> SHSingleLabelSample {
        setExpectations(expectedProjectIds: [projectId])
        context.perform {
            image.purpose = "testing"

            do {
                try context.save()
            } catch let error {
                XCTFail("Context save failed \(error)")
            }
        }
        self.waitForExpectations(timeout: 3.0)
        return image
    }

    private func testDeleteImageNotification(projectId: UUID, image: SHSingleLabelSample, context: NSManagedObjectContext) {
        setExpectations(expectedProjectIds: [projectId])
        context.perform {
            context.delete(image)

            do {
                try context.save()
            } catch let error {
                XCTFail("Context save failed \(error)")
            }
        }
        self.waitForExpectations(timeout: 3.0)
    }

    private func testDeleteLabelNotification(projectId: UUID, label: SHLabel, context: NSManagedObjectContext) {
        setExpectations(expectedProjectIds: [projectId])
        context.perform {
            context.delete(label)

            do {
                try context.save()
            } catch let error {
                XCTFail("Context save failed \(error)")
            }
        }
        self.waitForExpectations(timeout: 3.0)
    }

    private func testDeleteProjectNotification(project: SHSingleLabelClassifierProject, context: NSManagedObjectContext) {
        setExpectations(expectedProjectIds: [UUID(uuidString: project.id!)!])
        context.perform {
            context.delete(project)

            do {
                try context.save()
            } catch let error {
                XCTFail("Context save failed \(error)")
            }
        }
        self.waitForExpectations(timeout: 3.0)
    }
}
