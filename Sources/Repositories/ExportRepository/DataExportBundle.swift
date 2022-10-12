// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import UniformTypeIdentifiers
import SwiftUI
import os.log

struct DataExportBundle {

    let projectID: ProjectID
    let databaseStorageService: DatabaseStorageService

    func prepareExport() async throws -> URL {
        // get export folder for this project
        let projectExportFolder = try Self.projectExportFolder(for: projectID)

        let projectNameForExport = await fetchProjectNameForExport()

        // create a folder for this export
        let exportTitle = exportFolderName(projectName: projectNameForExport, date: Date())
        let exportURL = projectExportFolder.appendingPathComponent(exportTitle)
        let fileManager = FileManager.default
        try fileManager.createFolderIfNotPresent(folderURL: exportURL)

        // save export data
        try await saveDataset(tempURL: exportURL)
        os_log(.info, "Preparing dataset for export: save complete")

        // return ready URL
        return exportURL
    }

    private func exportFolderName(projectName: String, date: Date) -> String {
        "CoML \(projectName) \(date.exportFolderDateString)"
    }

    /// Returns a project name for export, falling back to "CoML Project" if something went wrong.
    private func fetchProjectNameForExport() async -> String {
        var projectMetadata: Project?

        do {
            projectMetadata = try await databaseStorageService.fetchProject(projectID: projectID)
        } catch let error {
            os_log(.error, #function, "Failed to fetch project metadata \(error)")
        }

        guard let projectMetadata else {
            return fallbackProjectNameForExport
        }

        return projectMetadata.title
    }

    /// The fallback project name, when the project name could not be fetched.
    var fallbackProjectNameForExport: String {
        "CoML Project"
    }

    private func saveDataset(tempURL: URL) async throws {
        try createDataTypeFolders(tempURL)

        let projectModelInfo = try databaseStorageService.fetchProjectModelInfo(projectID: projectID)
        let labels = projectModelInfo.labels
        for (index, label) in labels.enumerated() {
            do {
                try await saveLabel(label, labelIndex: index, projectModelInfo: projectModelInfo, tempURL: tempURL)
            } catch let error {
                os_log(.error, "Preparing dataset: Skipping folder for label \(label.labelString) for reason: \(error)")
            }
        }
    }

    private func saveLabel(_ label: LabelAnnotation,
                           labelIndex: Int,
                           projectModelInfo: ProjectModelInfo,
                           tempURL: URL) async throws {

        // Get raw samples for each data type
        let labelUUID = label.id.id
        let sampleIDsByDataType: [DataType: [UUID]] = [
            .training: projectModelInfo.sampleIDsByLabelUUID[labelUUID] ?? [],
            .testing: projectModelInfo.testSampleIDsByLabelUUID[labelUUID] ?? []
        ]

        // sanitize label name
        let fallbackName = "label_\(labelIndex)"
        let cleanLabelName = label.labelString.validated(previous: fallbackName)

        // create label folders
        try createLabelFolders(cleanLabelName, tempURL: tempURL)

        // write data
        try writeLabelFolders(cleanLabelName,
                              sampleIDsByDataType: sampleIDsByDataType,
                              mediaTypeExtension: UTType.jpeg.preferredFilenameExtension ?? "jpeg",
                              tempURL: tempURL)
    }

    private func createDataTypeFolders(_ tempURL: URL) throws {
        let fileManager = FileManager.default

        // create a folder for each data type
        for dataType in DataType.allCases {
            let bucketURL = tempURL.appendingPathComponent(dataType.directoryName)
            try fileManager.createFolderIfNotPresent(folderURL: bucketURL)
            os_log(.info, "Preparing dataset for export: created folder \(bucketURL)")
        }
    }

    private func createLabelFolders(_ labelName: String, tempURL: URL) throws {
        let fileManager = FileManager.default

        // create a label folder within each data type
        for dataType in DataType.allCases {
            // get data type folder
            let bucketURL = tempURL.appendingPathComponent(dataType.directoryName)

            // create label folder
            let labelURL = bucketURL.appendingPathComponent(labelName)
            try fileManager.createFolderIfNotPresent(folderURL: labelURL)
            os_log(.info, "Preparing dataset for export: created folder \(labelURL)")
        }
    }

    private func writeLabelFolders(_ labelName: String, sampleIDsByDataType: [DataType: [UUID]], mediaTypeExtension: String, tempURL: URL) throws {
        for (dataType, sampleIDs) in sampleIDsByDataType {

            // get label folder
            let bucketURL = tempURL.appendingPathComponent(dataType.directoryName)
            let labelURL = bucketURL.appendingPathComponent(labelName)

            // write out each sample in this bucket
            for sampleID in sampleIDs {
                // Use an autorelease pool to ensure that each sample data is released after we finish writing it
                // to disk.
                _ = try autoreleasepool {
                    let sampleURL = labelURL
                        .appendingPathComponent("\(labelName)-\(sampleID)")
                        .appendingPathExtension(mediaTypeExtension)

                    let sample = try databaseStorageService.fetchSample(sampleID: sampleID)
                    try sample.sampleData.write(to: sampleURL)
                }
            }

            // report success
            os_log(.info, "Finished saving data: \(labelName) \(dataType.purposeString) \(mediaTypeExtension)")
        }
    }
}

extension DataExportBundle {
//    static var fake: DataExportBundle {
//        .init(projectID: ProjectID(), databaseStorageService: DatabaseStorageServiceFake())
//    }

    /// The parent directory used for project export, scoped to a particular project. Not user-facing.
    /// Lives in the temporary directory.
    static func projectExportFolder(for projectID: ProjectID) throws -> URL {
        let exportTitle = "DataExport_\(projectID.uuidString)"
        let projectExportFolder = URL.temporaryDirectory.appendingPathComponent(exportTitle)
        let fileManager = FileManager.default
        try fileManager.createFolderIfNotPresent(folderURL: projectExportFolder)
        return projectExportFolder
    }

    /// Cleans up all project export data for the project with the specified ID.
    static func cleanupExportData(projectID: ProjectID) throws {
        // get export folder for this project
        let projectExportFolder = try Self.projectExportFolder(for: projectID)
        let fileManager = FileManager.default

        // delete folder
        if fileManager.fileExists(atPath: projectExportFolder.path()) {
            try fileManager.removeItem(at: projectExportFolder)
        }
    }
}

private extension Date {
    /// Returns a compactly formatted datetime string, ensuring that subsequent exports are probably uniquely named.
    var exportFolderDateString: String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = .autoupdatingCurrent
        return dateFormatter.string(from: self)
    }
}
