// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct LabelDetailInnerGridView<
    GridCardState: Identifiable,
    SubtitleText: View,
    GridCard: View,
    TitleView: View,
    ToolbarCameraButton: View,
    ToolbarPhotosButton: View
>: View {
    let gridCardStates: [GridCardState]
    let purposeString: String
    @ViewBuilder let subtitleText: () -> SubtitleText
    @ViewBuilder let gridCard: (GridCardState) -> GridCard
    @ViewBuilder let titleView: () -> TitleView
    @ViewBuilder let toolbarCameraButton: () -> ToolbarCameraButton
    @ViewBuilder let toolbarPhotoAlbumButton: () -> ToolbarPhotosButton

    var body: some View {
        VStack(alignment: .leading) {
            titleView()
                .font(.title2.bold())
            subtitleText()
                .font(.subheadline)
                .foregroundColor(Color(uiColor: .secondaryLabel))
            ScrollView(.vertical) {
                LazyVGrid(columns: gridItems, spacing: .tile.spacing) {
                    ForEach(gridCardStates) { state in
                        gridCard(state)
                    }
                }
            }
        }
        .padding()
        .toolbar {
            toolbarItems
        }
    }

    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: .tile.spacing), count: 7)
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(.images(purposeString.capitalized))
                .font(.headline)
        }
        ToolbarItem {
            toolbarCameraButton()
        }
        ToolbarItem {
            toolbarPhotoAlbumButton()
        }
    }
}
