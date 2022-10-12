// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import SwiftUI
import os.log

@MainActor
final class DataExportViewModel: ObservableObject {
    @Published var dataExportState: DataExportState

    private let exportRepository: ExportRepository

    init(exportRepository: ExportRepository) {
        self.exportRepository = exportRepository
        self.dataExportState = .prepareData
    }

    func resetDataExport() {
        Task {
            await resetDataExport()
        }
    }

    func prepareDataExport() {
        Task {
            await prepareDataExport()
        }
    }
}

// MARK: - Private

private extension DataExportViewModel {

    func resetDataExport() async {
        withAnimation {
            dataExportState = .cleanInProgress
        }

        await exportRepository.cleanupExportData()

        withAnimation {
            dataExportState = .prepareData
        }
    }

    func prepareDataExport() async {
        // start prep
        withAnimation {
            dataExportState = .prepInProgress
        }

        do {
            let url = try await exportRepository.prepareExportData()

            // prep complete
            withAnimation {
                dataExportState = .readyToExport(dataURL: url)
            }

        } catch let error {
            // notify user of an error
            dataExportState = .error
            os_log(.error, "Unable to prepare data export \(error)")
        }
    }
}

#if DEBUG

extension DataExportViewModel {

    static var fakePrepModel: Self {
        .fake(state: .prepareData)
    }

    static var fakeLoadingModel: Self {
        .fake(state: .prepInProgress)
    }

    static var fakeExportReadyModel: DataExportViewModel {
        .fake(state: .readyToExport(dataURL: .temporaryDirectory))
    }

    static var fakeCleanModel: DataExportViewModel {
        .fake(state: .cleanInProgress)
    }

    static var fakeErrorModel: DataExportViewModel {
        .fake(state: .error)
    }

    static func fake(state: DataExportState) -> Self {
        let result = Self(exportRepository: .fake)
        result.dataExportState = state
        return result
    }

    static var fake: Self {
        .fakePrepModel
    }
}

#endif
