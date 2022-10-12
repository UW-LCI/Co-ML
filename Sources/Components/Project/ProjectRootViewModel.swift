// Copyright 2026 Apple Inc. All rights reserved.
import Foundation
import UIKit
import Combine
import os.log

@MainActor
class ProjectRootViewModel: ObservableObject {
    // view state
    @Published var showSampleDetail: LabeledImageID?
    @Published private(set) var activePage: ProjectPage

    // importing photos
    @Published var showPhotoPicker = false
    @Published var showPhotoFilePicker = false
    private(set) var photoPickerSettings: PhotoPickerSettings?

    // Sharing button services & state
    @Published var isSharing = false
    @Published var showIcloudAlert = false
    @Published private(set) var sharingController: SharingController

    // view state to delete a label
    @Published var askToDeleteLabel: LabelAnnotation?
    @Published var showDeleteAlert = false

    // View state for image deletion prompt.
    @Published var deleteImagePromptState: DeleteImagePromptState?

    // services and project information
    let projectID: ProjectID
    let databaseStorageService: DatabaseStorageService
    let projectModelInfoRepository: ProjectModelInfoRepository
    let imageFetchRepository: ImageFetchRepository
    let evaluationRepository: EvaluationRepository
    let imageStorageService: ImageStorageService
    let modelStorageService: ModelStorageService
    let imageRepository: ImageRepository
    let validationRepository: ValidationRepository
    private let urlGenerator: URLGenerator
    let photoPickerModel: PhotoPickerModel

    // view models
    let exportViewModel: ExportViewModel
    let trainingDataViewModel: PrepareDataViewModel
    let evaluationViewModel: EvaluationViewModel
    let trainingViewModel: TrainingViewModel
    let projectTitleViewModel: ProjectTitleViewModel

    // return to projects gallery
    let exitProject: () -> Void

    init(project: Project,
         databaseStorageService: DatabaseStorageService,
         imageFetchRepository: ImageFetchRepository,
         exitProject: @escaping () -> Void) {
        self.projectID = project.id

        self.databaseStorageService = databaseStorageService
        self.imageFetchRepository = imageFetchRepository

        let sampleStorageService = SampleStorageServiceImpl(databaseStorageService: databaseStorageService)
        self.imageStorageService = ImageStorageServiceImpl(sampleStorageService: sampleStorageService)

        self.urlGenerator = URLGeneratorImpl(projectID: project.id)

        self.modelStorageService = ModelStorageServiceImpl(projectID: project.id,
                                             modelURL: urlGenerator.modelFileURL,
                                             modelMetadataURL: urlGenerator.projectModelInfoURL,
                                             modelType: .imageClassifier)

        self.exitProject = exitProject

        self.activePage = .trainingData // default landing page

        self.sharingController = SharingController(
            projectID: project.id,
            databaseStorageService: databaseStorageService
        )

        // view models
        validationRepository = ValidationRepositoryImpl(
            projectID: project.id,
            urlGenerator: urlGenerator)

        self.imageRepository = ImageRepositoryImpl(projectID: project.id, imageStorageService: imageStorageService)

        projectModelInfoRepository = ProjectModelInfoRepositoryImpl(
            projectID: project.id,
            databaseStorageService: databaseStorageService)

        self.trainingDataViewModel = PrepareDataViewModel(
            projectID: project.id,
            projectModelInfoRepository: projectModelInfoRepository,
            imageRepository: imageRepository,
            imageFetchRepository: imageFetchRepository)

        let datasetsRepository = DatasetsRepositoryImpl(projectModelInfoRepository: projectModelInfoRepository)

        let trainingAnalyticsService = TrainingAnalyticsServiceImpl(projectID: project.id)
        let trainingService = TrainingServiceImpl(
            project: project,
            urlGenerator: urlGenerator,
            datasetsRepository: datasetsRepository,
            validationRepository: validationRepository,
            analyticsService: trainingAnalyticsService,
            databaseStorageService: databaseStorageService)

        self.trainingViewModel = TrainingViewModel(
            project: project,
            projectModelInfoRepository: projectModelInfoRepository,
            trainingService: trainingService,
            modelStorageService: modelStorageService)

        let exportRepository = ExportRepositoryImpl(projectID: project.id,
                                              modelStorageService: modelStorageService,
                                              databaseStorageService: databaseStorageService)
        self.exportViewModel = ExportViewModel(exportRepository: exportRepository)

        self.photoPickerModel = PhotoPickerModel(projectID: project.id, imageStorageService: imageStorageService, photoSizer: PhotoSizerImpl())

        // evaluation view models
        evaluationRepository = EvaluationRepositoryImpl(
            projectID: project.id,
            projectModelInfoRepository: projectModelInfoRepository,
            imageFetchRepository: imageFetchRepository,
            validationRepository: validationRepository,
            modelStorageService: modelStorageService)

        self.evaluationViewModel = EvaluationViewModel(evaluationRepository: evaluationRepository,
                                                       imageFetchRepository: imageFetchRepository)

        self.projectTitleViewModel = ProjectTitleViewModel(
            projectID: project.id,
            initialTitle: project.title,
            databaseStorageService: databaseStorageService
        )
    }

    func rename(labelID: LabelID, newLabel: String) {
        Task(priority: .userInitiated) {
            do {
                try await databaseStorageService.update(labelWithID: labelID, newLabelString: newLabel)
            } catch {
                os_log("Error while renaming label \(labelID) : \(error)")
            }
        }
    }

    func deleteLabel(labelID: LabelID) {
        showDeleteAlert = false
        askToDeleteLabel = nil
        Task(priority: .userInitiated) {
            do {
                try await databaseStorageService.deleteLabel(id: labelID)
                os_log(.info, "Label successfully deleted: \(labelID)")
            } catch {
                os_log("Error while deleting label \(labelID) : \(error)")
            }
        }
    }

    func deleteImage(imageID: LabeledImageID) {
        Task(priority: .userInitiated) {
            do {
                try await databaseStorageService.deleteSample(sampleID: imageID.id)
                os_log(.info, "Image successfully deleted: \(imageID.idString)")
            } catch {
                os_log("Error while deleting image \(imageID.idString): \(error)")
            }
        }
    }

    func requestDeleteLabel(_ label: LabelAnnotation) {
        askToDeleteLabel = label
        showDeleteAlert = true
    }

    func requestDeleteImage(_ imageID: LabeledImageID) {
        Task(priority: .userInitiated) {
            var askToDeleteImageLabelName: String?
            do {
                let label = try await databaseStorageService.fetchLabel(labelID: imageID.labelID)
                askToDeleteImageLabelName = label?.labelString
            } catch {
                os_log("Error fetching label with ID \(imageID.labelID)")
            }
            deleteImagePromptState = DeleteImagePromptState(imageID: imageID, labelName: askToDeleteImageLabelName)
        }
    }

    func switchPage(to page: ProjectPage) {
        activePage = page
    }

    /// This updates the sharing controller but does not return any value directly
    func fetchShareInfo() async {
        sharingController.fetchShareInformation()
    }

    var isViewingTestingPage: Bool {
        activePage.dataType == .testing
    }

    func sampleDetailRepository(imageID: LabeledImageID) -> SampleDetailRepository {
        SampleDetailRepositoryImpl(sampleID: imageID.sampleID,
                                   dataType: activePage.dataType,
                                   databaseStorageService: databaseStorageService,
                                   initialLabelID: imageID.labelID)
    }

    func labelDetailRepository(labelID: LabelID, dataType: DataType) -> LabelDetailRepository {
        LabelDetailRepositoryImpl(labelID: labelID,
                                  dataType: dataType,
                                  projectModelInfoRepository: projectModelInfoRepository)
    }

    func evaluationLabelDetailRepository(labelID: LabelID) -> EvaluationLabelDetailRepository {
        EvaluationLabelDetailRepositoryImpl(labelID: labelID,
                                            evaluationRepository: evaluationRepository)
    }

    func evaluationSheetViewModel(imageID: LabeledImageID) -> EvaluationSheetViewModel {
        let sampleDetailRepository = sampleDetailRepository(imageID: imageID)
        let repository = EvaluationDetailRepositoryImpl(
            sampleID: imageID.sampleID,
            sampleDetailRepository: sampleDetailRepository,
            validationRepository: validationRepository)
        return EvaluationSheetViewModel(
            projectID: projectID,
            evaluationDetailsRepository: repository,
            imageFetchRepository: imageFetchRepository)
    }

    // another option to open the photo picker outside grid views
    func openPhotoPicker(settings: PhotoPickerSettings) {
        photoPickerSettings = settings
        showPhotoPicker = true
    }

    func openFilesAppPicker(settings: PhotoPickerSettings) {
        photoPickerSettings = settings
        showPhotoFilePicker = true
    }

    func importImages(uiImages: [UIImage]) {
        Task(priority: .userInitiated) {
            if let settings = photoPickerSettings {
                self.photoPickerModel.saveToProject(uiImages, saveSettings: settings)
            }
        }
    }

    func openSampleDetail(labelID: LabeledImageID) {
        showSampleDetail = labelID
    }

    /// When the Training or Evaluation views request an action, resolve it here
    /// Must resolve which data type, either training or testing, actions apply to, so that
    /// data gets saved in the right place
    func resolveGridActions(for dataType: DataType) -> @MainActor (GridViewAction) -> Void {
        func perform(action: GridViewAction) {
            switch action {
            case .showImage(let imageID):
                showSampleDetail = imageID

            case .photosAppImport(to: let label):
                openPhotoPicker(settings: PhotoPickerSettings(saveDestination: dataType, label: label))

            case .filesAppImport(to: let label):
                openFilesAppPicker(settings: PhotoPickerSettings(saveDestination: dataType, label: label))

            case .rename(let label, to: let newValue):
                rename(labelID: label.id, newLabel: newValue)

            case .delete(let label):
                requestDeleteLabel(label)

            case .deleteImage(let imageID):
                requestDeleteImage(imageID)
            }
        }
        // actions now configured for the correct data type
        return perform
    }
}

