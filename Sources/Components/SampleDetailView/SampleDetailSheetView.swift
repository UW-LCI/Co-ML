// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI
import os.log

struct SampleDetailSheetView: View {
    @StateObject private var viewModel: SampleDetailSheetViewModel
    @Environment(\.dismiss) private var dismissAction

    init(wrappedValue: @autoclosure @escaping () -> SampleDetailSheetViewModel) {
        _viewModel = StateObject(wrappedValue: wrappedValue())
    }

    var body: some View {
        panel
            .deleteSampleAlertPresenter(
                isPresented: $viewModel.isShowingDeleteAlert,
                sampleName: viewModel.selectedLabelName,
                delete: {
                    Task(priority: .userInitiated) {
                        do {
                            try await viewModel.delete()
                            // After delete has succeeded, we can dismiss the sample sheet
                            dismissAction()
                        } catch {
                            os_log(.error, "An error occurred deleting the sample: \(error)")
                            // Leaves the sample view onscreen
                        }
                    }
                })
            .moveSampleAlertPresenter(
                isPresented: $viewModel.isShowingMoveAlert,
                sampleName: viewModel.selectedLabelName,
                source: viewModel.currentDataTypeDescription,
                destination: viewModel.oppositeDataTypeDescription,
                move: {
                    Task(priority: .userInitiated) {
                        do {
                            try await viewModel.moveToOppositeDataType()
                            // After the move has succeeded, we can dismiss the sample sheet.
                            dismissAction()
                        } catch {
                            os_log(.error, "An error occurred moving the sample: \(error)")
                            // Leaves the sample view onscreen
                        }
                    }
                })
    }

    private var panel: some View {
        VStack {
            toolbarView
            Spacer(minLength: 40)
            imageView
            labelSelectionArea
        }
        .frame(width: 400, height: 410)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(.modal.cornerRadius)
        .shadow(radius: 5)
    }

    @ViewBuilder
    private var toolbarView: some View {
        if viewModel.showToolbar {
            SharedSheetToolbarView(
                localizedTitle: viewModel.selectedLabelName,
                deleteButtonAction: {
                    viewModel.isShowingDeleteAlert = true
                },
                doneButtonAction: {
                    dismissAction()
                },
                moveAction: {
                    viewModel.isShowingMoveAlert = true
                }
            )
        }
    }

    private var imageView: some View {
        Image(uiImage: viewModel.image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 200.0, height: 200.0)
            .clipped()
            .accessibilityIgnoresInvertColors()
    }

    @ViewBuilder
    private var labelSelectionArea: some View {
        if let selectedLabelID = viewModel.sampleDetails?.selectedLabelID {
            SampleDetailLabelSelectionView(labels: viewModel.labels,
                                           selectedLabelID: selectedLabelID) {
                viewModel.updateSelectedLabel(labelID: $0)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    SampleDetailSheetPreviewView()
}

struct SampleDetailSheetPreviewView: View {

    @StateObject private var viewModel: SampleDetailSheetViewModel = .fake

    var body: some View {
        Rectangle()
            .ignoresSafeArea(.all)
            .foregroundStyle(.secondary)
            .fullScreenCover(isPresented: .constant(true)) {
                SampleDetailSheetView(wrappedValue: viewModel)
                    .background {
                        ClearBackgroundView()
                    }
            }
    }
}

#endif
