// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// A service that provides the metadata about a project and aids project export
protocol ExportRepository {

    /// Fetch metadata about this project. Returns `nil` if no model exists.
    func fetchProjectInfo() async -> ProjectInfo?

    /// Prepare an export-ready URL with the given model name.
    func prepareExportModel(modelName: String) async throws -> URL

    /// Prepare an export-ready URL
    func prepareExportData() async throws -> URL

    /// Cleanup by deleting any temporary data export files
    func cleanupExportData() async
}
