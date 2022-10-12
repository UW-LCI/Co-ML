// Copyright 2026 Apple Inc. All rights reserved.

import UIKit

#if DEBUG

enum SampleDetailViewPreviewTestData {
    static let projectID = ProjectID(uuidString: "cc255a54-de0c-419e-b247-12c859abdc78")!
    static let labelID = LabelID(id: UUID(uuidString: "de144392-960a-4ac4-ac88-75987c073d80")!, projectID: projectID)

    static let imageID1 = LabeledImageID(existingSampleID: UUID(uuidString: "d30d2733-3ba7-4938-bf83-b04f225bd474")!, labelID: labelID)
    static let imageID2 = LabeledImageID(existingSampleID: UUID(uuidString: "06af60ba-4078-4643-9843-0d4c7e7917b4")!, labelID: labelID)
    static let imageID3 = LabeledImageID(existingSampleID: UUID(uuidString: "5e25c526-c554-4767-96eb-9cce5c4461df")!, labelID: labelID)
    static let imageID4 = LabeledImageID(existingSampleID: UUID(uuidString: "87d504a5-73eb-4263-b535-76d24ab2c052")!, labelID: labelID)
    static let imageID5 = LabeledImageID(existingSampleID: UUID(uuidString: "ba22d853-8d68-4481-88cf-2932ae697322")!, labelID: labelID)
    static let imageID6 = LabeledImageID(existingSampleID: UUID(uuidString: "fdc9c9e0-9ac0-4907-a37e-67c2a8329dbe")!, labelID: labelID)
    static let imageID7 = LabeledImageID(existingSampleID: UUID(uuidString: "ae0bde81-fed5-4f64-a651-b43255d9472e")!, labelID: labelID)

    static let imageID11 = LabeledImageID(existingSampleID: UUID(uuidString: "af06ad65-b127-4cfe-94e8-2d9ea5fa94dc")!, labelID: labelID)
    static let imageID12 = LabeledImageID(existingSampleID: UUID(uuidString: "03e0a3b5-5958-48e6-a24a-23502afbfbd8")!, labelID: labelID)
    static let imageID13 = LabeledImageID(existingSampleID: UUID(uuidString: "5271f8c2-0df8-444e-baaa-8f55e922232b")!, labelID: labelID)
    static let imageID14 = LabeledImageID(existingSampleID: UUID(uuidString: "7899f219-d05b-4328-8abb-ac3611a7a071")!, labelID: labelID)
    static let imageID15 = LabeledImageID(existingSampleID: UUID(uuidString: "a5adaa56-bba3-4624-aedf-68b974f9c47f")!, labelID: labelID)
    static let imageID16 = LabeledImageID(existingSampleID: UUID(uuidString: "a7f57ee5-c186-4f10-8a9f-bddda46a956e")!, labelID: labelID)
    static let imageID17 = LabeledImageID(existingSampleID: UUID(uuidString: "b3a0d8a6-950d-4c02-8818-d88ba2ee48c5")!, labelID: labelID)

    static let date1 = Date(timeIntervalSince1970: 1_675_809_660.0) // Feb. 7, 2:41:00pm
    static let date2 = Date(timeIntervalSince1970: 1_675_809_720.0) // Feb. 7, 2:42:00pm
    static let date3 = Date(timeIntervalSince1970: 1_675_809_780.0) // Feb. 7, 2:43:00pm
    static let date4 = Date(timeIntervalSince1970: 1_675_809_840.0) // Feb. 7, 2:44:00pm
    static let date5 = Date(timeIntervalSince1970: 1_675_809_900.0) // Feb. 7, 2:45:00pm
    static let date6 = Date(timeIntervalSince1970: 1_675_809_960.0) // Feb. 7, 2:46:00pm
    static let date7 = Date(timeIntervalSince1970: 1_675_810_020.0) // Feb. 7, 2:47:00pm

    static let images = [
        LabeledImage(existingLabeledImageID: imageID1, image: UIImage(systemName: "globe.americas")!, creationDate: date1),
        LabeledImage(existingLabeledImageID: imageID2, image: UIImage(systemName: "sun.max.circle")!, creationDate: date2),
        LabeledImage(existingLabeledImageID: imageID3, image: UIImage(systemName: "moon.dust")!, creationDate: date3),
        LabeledImage(existingLabeledImageID: imageID4, image: UIImage(systemName: "cloud.drizzle")!, creationDate: date4),
        LabeledImage(existingLabeledImageID: imageID5, image: UIImage(systemName: "wind.snow")!, creationDate: date5),
        LabeledImage(existingLabeledImageID: imageID6, image: UIImage(systemName: "tornado")!, creationDate: date6),
        LabeledImage(existingLabeledImageID: imageID7, image: UIImage(systemName: "flame")!, creationDate: date7),
    ]

    static let images2 = [
        LabeledImage(existingLabeledImageID: imageID11, image: UIImage(systemName: "globe.americas")!, creationDate: date1),
        LabeledImage(existingLabeledImageID: imageID12, image: UIImage(systemName: "sun.max.circle")!, creationDate: date2),
        LabeledImage(existingLabeledImageID: imageID13, image: UIImage(systemName: "moon.dust")!, creationDate: date3),
        LabeledImage(existingLabeledImageID: imageID14, image: UIImage(systemName: "cloud.drizzle")!, creationDate: date4),
        LabeledImage(existingLabeledImageID: imageID15, image: UIImage(systemName: "wind.snow")!, creationDate: date5),
        LabeledImage(existingLabeledImageID: imageID16, image: UIImage(systemName: "tornado")!, creationDate: date6),
        LabeledImage(existingLabeledImageID: imageID17, image: UIImage(systemName: "flame")!, creationDate: date7),
    ]

    static let labels = [
        LabelAnnotation(labelID: labelID, label: "Banana")
    ]
}

#endif
