// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

@MainActor
struct ExportView: View {
    @ObservedObject var viewModel: ExportViewModel

    var body: some View {
        ExportInnerView(viewState: viewModel.viewState, dataExportViewModel: viewModel.dataExportViewModel)
        .task {
            // update export page to the latest information
            await viewModel.fetchExportInfo()
        }
    }
}

private struct ExportInnerView: View {
    let viewState: ExportViewState
    let dataExportViewModel: DataExportViewModel

    var body: some View {
        HStack(alignment: .top) {
            switch viewState {
            case .loading:
                ProgressView()

            case .unavailable:
                VStack {
                    ModelExportPane(projectInfo: nil) {
                        Button {
                            // No-op
                        } label: {
                            Text(.exportModel)
                        }
                        .disabled(true)
                    }
                    .topPanelStyle()

                    DataExportPane(viewModel: dataExportViewModel)
                        .bottomPanelStyle()
                }
                .padding()

            case .loaded(let projectInfo, let exportURL):
                VStack {
                    ModelExportPane(projectInfo: projectInfo) {
                        ShareLink(item: exportURL) {
                            Text(.exportModel)
                        }
                    }
                    .topPanelStyle()

                    DataExportPane(viewModel: dataExportViewModel)
                        .bottomPanelStyle()
                }
                .padding()
            }
        }
    }
}

private struct TopPanelViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: .trainingCard.cornerRadius))
            .padding(.bottom)
    }
}

private struct BottomPanelViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: .trainingCard.cornerRadius))
    }
}

private extension View {
    func topPanelStyle() -> some View {
        modifier(TopPanelViewModifier())
    }

    func bottomPanelStyle() -> some View {
        modifier(BottomPanelViewModifier())
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Static loaded") {
    ExportInnerView(
        viewState: .fake,
        dataExportViewModel: .fake
    )
}

#Preview("Static Loading") {
    ExportInnerView(
        viewState: .loading,
        dataExportViewModel: .fake
    )
}

#Preview("Static unavailable") {
    ExportInnerView(
        viewState: .unavailable,
        dataExportViewModel: .fake
    )
}

#Preview("Static many labels") {
    ExportInnerView(
        viewState: .fakeWithManyLabels,
        dataExportViewModel: .fake
    )
}

#endif
