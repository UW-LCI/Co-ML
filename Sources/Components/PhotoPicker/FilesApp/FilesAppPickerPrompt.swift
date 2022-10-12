// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct FilesAppPickerPrompt: ViewModifier {
    @State private var viewModel: FilesAppPickerViewModel
    @Binding var showPicker: Bool

    init(showPicker: Binding<Bool>,
         preprocessPhoto: @escaping (UIImage) -> UIImage,
         importPhotos: @escaping ([UIImage]) -> Void) {
        _showPicker = showPicker
        _viewModel = State(initialValue: FilesAppPickerViewModel(preprocessPhoto: preprocessPhoto, importPhotos: importPhotos))
    }

    func body(content: Content) -> some View {
        content.fileImporter(
            isPresented: $showPicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true,
            onCompletion: viewModel.importFiles(result:)
        )
    }
}
