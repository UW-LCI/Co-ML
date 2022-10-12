// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct ProjectTileView: View {
    private enum Constants {
        static let imageWidth: CGFloat = 54
        static let imageHeight: CGFloat = 54
        static let informationFontSize: CGFloat = 12
        static let imageGridBottomPadding: CGFloat = 13
        static let projectNamebottomPadding: CGFloat = 2
        static let outsidePadding: CGFloat = 12
    }

    let viewState: ProjectTileViewState
    let isSelected: Bool
    let isEditing: Bool
    let fetchImage: (UUID) async throws -> UIImage

    var body: some View {
        VStack(alignment: .leading) {
            FixedGrid(builder: FixedGridBuilder(items: viewState.thumbnails, rows: 2, columns: 4)) { thumbnailType in
                switch thumbnailType {
                case let .image(sampleID):
                    SampleImageView {
                        try await fetchImage(sampleID)
                    }
                    .frame(width: Constants.imageWidth, height: Constants.imageHeight)
                    .cornerRadius(6)

                case .placeholder:
                    Rectangle()
                        .frame(
                            width: Constants.imageWidth,
                            height: Constants.imageHeight
                        )
                        .cornerRadius(6)
                        .foregroundColor(Color(.secondarySystemBackground))
                }
            }
            .accessibilityElement(children: .ignore)
            .padding(.bottom, 13)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    LabeledContent(String(localized: .project), value: viewState.projectTitle)
                        .labelsHidden()
                        .font(.system(size: 15))
                        .lineLimit(1)
                        .accessibilityAddTraits(.isHeader)

                    if isEditing {
                        Spacer()
                            .overlay(alignment: .trailing) {
                                Label(.selected, systemImage: isSelected ? "checkmark.circle.fill" : "circle")
                                    .labelStyle(.iconOnly)
                                    .accessibilityElement(children: .ignore)
                                    .symbolRenderingMode(.multicolor)
                            }
                    }
                }

                Group {
                    LabeledContent(String(localized: .labels), value: viewState.labelNamesDisplayString)
                    .lineLimit(1)

                    SampleCountLabeledContent(sampleCount: viewState.totalSampleCount)
                }
                .labelsHidden()
                .font(.system(size: Constants.informationFontSize))
                .foregroundColor(.secondary)
            }
            .padding(.bottom, 12)

            HStack {
                LabeledContent(String(localized: .createdAt), value: viewState.createdAtFormatted)
                    .labelsHidden()
                    .font(.system(size: Constants.informationFontSize))
                    .foregroundColor(.secondary)

                Spacer()

                if viewState.isShared {
                    Label(.shared, systemImage: "person.3.fill")
                        .labelStyle(.iconOnly)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Constants.outsidePadding)
        .contentShape(Rectangle())

    }
}

/// Private sample count view facilitating plurals table testing.
private struct SampleCountLabeledContent: View {
    let sampleCount: Int

    var body: some View {
        LabeledContent {
            Text(.imageCountSubtitle(sampleCount))
        } label: {
            Text(.numberOfImages)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    ProjectTileView(
        viewState: ProjectTileViewState(
            project: Project(
                id: .fakeProjectID,
                title: "Static Project",
                createdAt: .date1,
                shareState: .shareOwner,
                labelNames: ["Apples", "Bananas", "Carrots"]
            ),
            thumbnails: [
                .image(.fakeApple1SampleUUID),
                .image(.fakeApple2SampleUUID),
                .image(.fakeApple3SampleUUID),
                .placeholder,
                .placeholder,
                .placeholder,
                .placeholder,
                .placeholder
            ],
            totalSampleCount: 3
        ),
        isSelected: false,
        isEditing: false,
        fetchImage: ImageFetchRepositoryFake.fetchImage
    )
}

#Preview("Sample counts") {
    VStack {
        SampleCountLabeledContent(sampleCount: 0)
        SampleCountLabeledContent(sampleCount: 1)
        SampleCountLabeledContent(sampleCount: 2350)
    }
    .labelsHidden()
}

#endif
