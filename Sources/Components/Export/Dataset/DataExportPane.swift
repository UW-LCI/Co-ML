// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct DataExportPane: View {

    @ObservedObject var viewModel: DataExportViewModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .bottom) {
                Text(.data)
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                switch viewModel.dataExportState {
                case .prepareData:
                    prepareDataButton()

                case .prepInProgress:
                    loadingView

                case .readyToExport(let dataURL):
                    shareLinkView(dataURL)

                case .cleanInProgress:
                    cleaningView

                case .error:
                    errorView
                }
            }
            Text(.exportAllTrainingAndTestImages)
                .foregroundColor(.secondary)
        }
        .padding(20)
        Spacer()
    }

    private func prepareDataButton(disabled: Bool = false) -> some View {
        Button {
            viewModel.prepareDataExport()
        } label: {
            Label {
                Text(.prepareDataForExport)
            } icon: {
                Image(systemName: "shippingbox.fill")
            }
        }
        .disabled(disabled)
    }

    private var loadingView: some View {
        HStack(spacing: 10) {
            ProgressView()
            prepareDataButton(disabled: true)
        }
    }

    @ViewBuilder
    private func shareLinkView(_ dataURL: URL) -> some View {
        HStack {
            shareButton(url: dataURL)
            resetButton()
        }
    }

    private var errorView: some View {
        HStack {
            Text(.anErrorOccurredWhilePreparingDataForExportTryAgain)
            resetButton()
        }
    }

    private var cleaningView: some View {
        HStack(spacing: 10) {
            ProgressView()
            shareButton(url: nil)
            resetButton(disabled: true)
        }
    }

    private func resetButton(disabled: Bool = false) -> some View {
        Button {
            viewModel.resetDataExport()
        } label: {
            Label(.reset, systemImage: "arrow.clockwise")
        }
        .disabled(disabled)
    }

    @ViewBuilder
    private func shareButton(url: URL?) -> some View {
        if let url {
            ShareLink(.exportData, item: url)
        } else {
            Button {
                // No-op
            } label: {
                Label {
                    Text(.exportData)
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .disabled(true)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Static Prepare Data") {
    DataExportPane(viewModel: .fakePrepModel)
}

#Preview("Static Loading") {
    DataExportPane(viewModel: .fakeLoadingModel)
}

#Preview("Static Export Data") {
    DataExportPane(viewModel: .fakeExportReadyModel)
}

#Preview("Static Error") {
    DataExportPane(viewModel: .fakeErrorModel)
}

#Preview("Static Clean in Progress") {
    DataExportPane(viewModel: .fakeCleanModel)
}

#endif
