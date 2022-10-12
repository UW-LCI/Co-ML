// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import UIKit

/// An image with an identifier corresponding to its Sample ID, as well as a creationDate that may be used for sorting.
struct LabeledImage: Identifiable, Equatable, Hashable, CustomStringConvertible {
    let id: LabeledImageID
    let image: UIImage
    let creationDate: Date
    let dataType: DataType

    /// Used for creating a _new_ labeled image associated with a given label, by generating a new labeled image ID and
    /// setting creationDate to the current date.
    init(image: UIImage, labelID: LabelID, dataType: DataType = .training) {
        self.id = LabeledImageID(labelID: labelID)
        self.image = image
        self.dataType = dataType
        self.creationDate = Date()
    }

    /// Used for updating an _existing_ labeled image by replacing an image in place.
    init(existingLabeledImage: LabeledImage, image: UIImage) {
        self.image = image
        self.id = existingLabeledImage.id
        self.creationDate = existingLabeledImage.creationDate
        self.dataType = existingLabeledImage.dataType
    }

    /// Used for populating an _existing_ labeled image, for example when passing up an image from storage.
    init(existingLabeledImageID: LabeledImageID, image: UIImage, creationDate: Date, dataType: DataType = .training) {
        self.id = existingLabeledImageID
        self.image = image
        self.creationDate = creationDate
        self.dataType = dataType
    }

    /// Used for updating an _existing_ labeled image by changing its associated label.
    init(existingLabeledImage: LabeledImage, newLabelID: LabelID) {
        self.image = existingLabeledImage.image
        self.creationDate = existingLabeledImage.creationDate
        self.dataType = existingLabeledImage.dataType
        self.id = LabeledImageID(existingSampleID: existingLabeledImage.sampleID, newLabelID: newLabelID)
    }

    var idString: String {
        id.idString
    }

    var projectID: ProjectID {
        id.projectID
    }

    var labelID: LabelID {
        id.labelID
    }

    var sampleID: UUID {
        id.sampleID
    }

    // MARK: - CustomStringConvertible

    var description: String {
        "LabeledImage \(id)"
    }
}

#if DEBUG

extension LabeledImage {
    // Original set
    static let fakeApple1 = LabeledImage(existingLabeledImageID: .fakeApple1id, image: UIImage(systemName: "globe.americas")!, creationDate: .date1)
    static let fakeApple2 = LabeledImage(existingLabeledImageID: .fakeApple2id, image: UIImage(systemName: "sun.max.circle")!, creationDate: .date2)
    static let fakeApple3 = LabeledImage(existingLabeledImageID: .fakeApple3id, image: UIImage(systemName: "moon.dust")!, creationDate: .date3)
    static let fakeApple4 = LabeledImage(existingLabeledImageID: .fakeApple4id, image: UIImage(systemName: "cloud.drizzle")!, creationDate: .date4)
    static let fakeBanana1 = LabeledImage(existingLabeledImageID: .fakeBanana1id, image: UIImage(systemName: "wind.snow")!, creationDate: .date5)
    static let fakeBanana2 = LabeledImage(existingLabeledImageID: .fakeBanana2id, image: UIImage(systemName: "tornado")!, creationDate: .date6)
    static let fakeBanana3 = LabeledImage(existingLabeledImageID: .fakeBanana3id, image: UIImage(systemName: "flame")!, creationDate: .date7)

    // More preview/test images
    static let fakeApple5 = LabeledImage(existingLabeledImageID: .fakeApple5id, image: UIImage(systemName: "globe.americas")!, creationDate: .date8)
    static let fakeApple6 = LabeledImage(existingLabeledImageID: .fakeApple6id, image: UIImage(systemName: "sun.max.circle")!, creationDate: .date9)
    static let fakeApple7 = LabeledImage(existingLabeledImageID: .fakeApple7id, image: UIImage(systemName: "moon.dust")!, creationDate: .date10)
    static let fakeApple8 = LabeledImage(existingLabeledImageID: .fakeApple8id, image: UIImage(systemName: "cloud.drizzle")!, creationDate: .date11)
    static let fakeApple9 = LabeledImage(existingLabeledImageID: .fakeApple9id, image: UIImage(systemName: "globe.americas")!, creationDate: .date12)
    static let fakeBanana4 = LabeledImage(existingLabeledImageID: .fakeBanana4id, image: UIImage(systemName: "wind.snow")!, creationDate: .date13)
    static let fakeBanana5 = LabeledImage(existingLabeledImageID: .fakeBanana5id, image: UIImage(systemName: "tornado")!, creationDate: .date14)
    static let fakeBanana6 = LabeledImage(existingLabeledImageID: .fakeBanana6id, image: UIImage(systemName: "flame")!, creationDate: .date15)
    static let fakeBanana7 = LabeledImage(existingLabeledImageID: .fakeBanana7id, image: UIImage(systemName: "wind.snow")!, creationDate: .date16)
    static let fakeBanana8 = LabeledImage(existingLabeledImageID: .fakeBanana8id, image: UIImage(systemName: "tornado")!, creationDate: .date17)
    static let fakeBanana9 = LabeledImage(existingLabeledImageID: .fakeBanana9id, image: UIImage(systemName: "flame")!, creationDate: .date18)
}

extension [LabelID: [LabeledImage]] {
    static let fakeImagesByLabel: Self = [
        .fakeAppleLabelID: [
            .fakeApple1,
            .fakeApple2,
            .fakeApple3
        ],
        .fakeBananaLabelID: [
            .fakeBanana1,
            .fakeBanana2
        ],
        .fakeCarrotLabelID: []
    ]
}

#endif
