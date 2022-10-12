// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI
import PhotosUI

struct PhotosAppPickerPrompt: ViewModifier {
    @StateObject private var viewModel: PhotosImportViewModel
    @Binding var showPicker: Bool

    init(showPicker: Binding<Bool>,
         preprocessPhoto: @escaping (UIImage) -> UIImage,
         importPhotos: @escaping ([UIImage]) -> Void) {
        _showPicker = showPicker
        _viewModel = StateObject(wrappedValue: PhotosImportViewModel(preprocessPhoto: preprocessPhoto, importPhotos: importPhotos))
    }

    func body(content: Content) -> some View {
        content.photosPicker(isPresented: $showPicker,
                             selection: $viewModel.imageSelection,
                             matching: .images,
                             photoLibrary: .shared())
    }
}
