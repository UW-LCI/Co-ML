// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct ModelExportPane<ExportButtonView: View>: View {
    let projectInfo: ProjectInfo?

    let exportButtonView: () -> ExportButtonView

    var body: some View {
        VStack {
            HStack {
                Text(.model)
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                exportButtonView()
            }

            if let projectInfo, let dateTrained = projectInfo.dateTrained {
                ProjectInfoInnerView(projectInfo: projectInfo,
                                     dateTrained: dateTrained)

            } else {
                ExportUnavailableView()
            }
        }
        .padding(20)
    }
}

private struct ProjectInfoInnerView: View {
    let projectInfo: ProjectInfo
    let dateTrained: Date

    var body: some View {
        VStack(alignment: .leading) {
            Text(.lastTrained(dateTrained.formatted(.relative(presentation: .named))))
                .foregroundColor(.secondary)

            GeometryReader { tableGeometry in
                Table(projectInfo.modelExportContent) {
                    // Table expects columns, but we don't want to the column labels to be visible - so passing in empty values for columns

                    TableColumn("", value: \.label)
                        .width(tableGeometry.size.width * 0.25)

                    TableColumn("") { row in
                        Text(row.value).lineLimit(4)
                    }
                }
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
            }
        }
    }
}

private extension ProjectInfo {

    var modelExportContent: [ExportRowItem] {
        [
            ExportRowItem(
                label: String(localized: .projectType),
                value: projectType.localized),

            ExportRowItem(
                label: String(localized: .filename),
                value: prettyModelName),

            ExportRowItem(
                label: String(localized: .documentType),
                value: documentType),

            ExportRowItem(
                label: String(localized: .size),
                value: fileSizeDescription),

            ExportRowItem(
                label: String(localized: .labels),
                value: labelNames.formatted(.list(type: .and)))
        ]
    }

    private var fileSizeDescription: String {
        ByteCountFormatter.string(fromByteCount: sizeInBytes, countStyle: .file)
    }
}

// MARK: - Previews

#if DEBUG

#Preview(traits: .landscapeLeft) {
    ModelExportPane(projectInfo: ProjectInfo.fake) {
        ShareLink(
            item: .temporaryDirectory,
            subject: Text(verbatim: "Core ML Model")
        ) {
            Text(verbatim: "Export Model")
        }
        .buttonStyle(.borderedProminent)
    }
}

#endif
