// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI
import os.log

@MainActor
struct ProjectRootView: View {

    @StateObject private var viewModel: ProjectRootViewModel
    @StateObject private var titleViewModel: ProjectTitleViewModel

    /// Create the view using a deferred constructor.
    /// This allows the ViewModel to be constructed at the call site safely without constructing too many copies of the model.
    ///
    ///     var body: some View {
    ///       ProjectRootView(ProjectViewModel(
    ///         project: p, storageService: s, imageStorageService: i, exit: exit
    ///       ))
    init(wrappedValue: @autoclosure @escaping () -> ProjectRootViewModel, wrappedTitleViewModel: @autoclosure @escaping () -> ProjectTitleViewModel) {
        _viewModel = StateObject(wrappedValue: wrappedValue())
        _titleViewModel = StateObject(wrappedValue: wrappedTitleViewModel())
    }

    var body: some View {
        ProjectPageView(viewModel: viewModel, title: titleViewModel.editableTitle)
            .navigationDestination(for: ProjectFullScreenRoute.self) { [weak viewModel] screen in
                if let viewModel {
                    Group {
                        switch screen {
                        case .cameraPage(let projectID, let settings):
                            CameraView( // This needs to be inline to avoid an unexpected retain cycle
                                cameraSettings: settings,
                                projectID: projectID,
                                projectModelInfoRepository: viewModel.projectModelInfoRepository,
                                imageFetchRepository: viewModel.imageFetchRepository,
                                imageRepository: viewModel.imageRepository,
                                modelStorageService: viewModel.modelStorageService) { [weak viewModel] imageID in
                                    viewModel?.showSampleDetail = imageID
                                }

                        case let .labelDetailPage(projectID, labelAnnotation, dataType, _):
                            if dataType == .testing {
                                EvaluationLabelDetailView(
                                    evaluationLabelDetailRepository: viewModel.evaluationLabelDetailRepository(labelID: labelAnnotation.id),
                                    imageFetchRepository: viewModel.imageFetchRepository,
                                    cameraRoute: ProjectFullScreenRoute.cameraPage(projectID: projectID,
                                                                                   settings: .init(
                                                                                    saveDestination: dataType,
                                                                                    viewMode: .collectionMode)),
                                    gridViewAction: viewModel.resolveGridActions(for: dataType))
                            } else {
                                LabelDetailView( // This needs to be inline to avoid an unexpected retain cycle
                                    labelAnnotation: labelAnnotation,
                                    dataType: dataType,
                                    projectID: projectID,
                                    imageStorageService: viewModel.imageStorageService,
                                    labelDetailRepository: viewModel.labelDetailRepository(labelID: labelAnnotation.id,
                                                                                           dataType: dataType),
                                    imageFetchRepository: viewModel.imageFetchRepository,
                                    databaseStorageService: viewModel.databaseStorageService,
                                    gridViewAction: viewModel.resolveGridActions(for: dataType)
                                )
                            }
                        }
                    }
                }
            }
            .fullScreenCover(item: $viewModel.showSampleDetail) { labeledImageID in
                openSampleDetailModal(labeledImageID)
            }
            .modifier(DeleteLabelPrompt(showDeleteAlert: $viewModel.showDeleteAlert,
                                        askToDeleteLabel: $viewModel.askToDeleteLabel,
                                        deleteLabel: viewModel.deleteLabel(labelID:)))
            .modifier(DeleteImagePrompt(promptState: $viewModel.deleteImagePromptState,
                                        deleteImage: viewModel.deleteImage(imageID:)))
            .modifier(FilesAppPickerPrompt(showPicker: $viewModel.showPhotoFilePicker,
                                           preprocessPhoto: viewModel.photoPickerModel.preprocessImage(rawImage:),
                                           importPhotos: viewModel.importImages(uiImages:)))
            .modifier(PhotosAppPickerPrompt(showPicker: $viewModel.showPhotoPicker,
                                            preprocessPhoto: viewModel.photoPickerModel.preprocessImage(rawImage:),
                                            importPhotos: viewModel.importImages(uiImages:)))
            .alert(
                .notSignedIn,
                isPresented: $viewModel.showIcloudAlert,
                actions: {
                    Button(role: .cancel) {
                        viewModel.showIcloudAlert = false
                    } label: {
                        Text(.cancel)
                    }
                    Button {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        viewModel.showIcloudAlert = false
                    } label: {
                        Text(.settings)
                    }

                }, message: {
                    Text(.youMustSignInToICloudToShare)
                }
            )
            .task {
                // prep views
                await viewModel.fetchShareInfo()
            }
    }

    // MARK: modals and sheets

    @ViewBuilder
    private func openSampleDetailModal(_ labeledImageID: LabeledImageID) -> some View {
        ZStack {
            DismissBackgroundView()
                .background(ClearBackgroundView())

            if viewModel.isViewingTestingPage {
                EvaluationSheetView(
                    wrappedValue: viewModel.evaluationSheetViewModel(imageID: labeledImageID)
                )
            } else {
                SampleDetailSheetView(
                    wrappedValue: SampleDetailSheetViewModel(
                        sampleDetailRepository: viewModel.sampleDetailRepository(imageID: labeledImageID)))
            }
        }
    }

}

