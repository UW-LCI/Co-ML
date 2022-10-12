// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import SwiftUI
import Combine
import os.log

@MainActor
final class ExportViewModel: ObservableObject {

    @Published private(set) var viewState: ExportViewState = .loading

    let dataExportViewModel: DataExportViewModel

    private var exportRepository: ExportRepository
    private var projectNotificationObserver: Cancellable?

    init(exportRepository: ExportRepository) {
        self.exportRepository = exportRepository
        dataExportViewModel = DataExportViewModel(exportRepository: exportRepository)
        addNotificationObservers()
    }

    deinit {
        projectNotificationObserver?.cancel()
    }

    func fetchExportInfo() async {
        let projectInfo = await exportRepository.fetchProjectInfo()
        guard let projectInfo else {
            viewState = .unavailable
            return
        }
        do {
            let exportURL = try await exportRepository.prepareExportModel(modelName: projectInfo.prettyModelName)
            viewState = .loaded(projectInfo: projectInfo, exportURL: exportURL)
        } catch {
            os_log(.error, "Failed to generate exportURL: \(error)")
            viewState = .unavailable
        }
    }

    private func addNotificationObservers() {
        projectNotificationObserver = NotificationCenter.default
            .publisher(for: .projectsUpdated)
            .throttle(for: 1.0, scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.fetchExportInfo()
                }
            }
    }
}

#if DEBUG

extension ExportViewModel {
    static let fake = ExportViewModel(exportRepository: .fake)
}

#endif
