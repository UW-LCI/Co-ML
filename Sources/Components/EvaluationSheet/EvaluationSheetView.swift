// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI
import os.log

struct EvaluationSheetView: View {
    @StateObject private var viewModel: EvaluationSheetViewModel
    @Environment(\.dismiss) private var dismissAction

    init(wrappedValue: @autoclosure @escaping () -> EvaluationSheetViewModel) {
        _viewModel = StateObject(wrappedValue: wrappedValue())
    }

    var body: some View {
        EvaluationSheetInnerView(
            state: viewModel.viewState,
            fetchImage: viewModel.fetchImage,
            changeExpectedLabel: {
                viewModel.changeExpectedLabel(labelID: $0)
            },
            delete: {
                viewModel.isShowingDeleteAlert = true
            },
            dismiss: {
                dismissAction()
            },
            moveToTraining: {
                viewModel.isShowingMoveAlert = true
            }
        )
        .task {
            await viewModel.monitorChanges()
        }
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
            }
        )
    }
}
