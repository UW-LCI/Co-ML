// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI
import os.log

struct CameraLabelPicker: View {

    @Binding var selection: LabelAnnotation?
    let labels: [LabelAnnotation]

    var body: some View {
        Picker(
            selection: $selection,
            label: Text(.selectLabel)
        ) {
            ForEach(labels) { label in
                Text(label.labelString)
                    // _?(label) is equivalent to Optional<LabelAnnotation>.some(label)
                    .tag(_?(label))
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .tile.width)
        .fixedSize(horizontal: true, vertical: true)
        .pickerStyle(.wheel)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(.selectLabel)
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    CameraLabelPickerPreviewView()
}

struct CameraLabelPickerPreviewView: View {
    @State private var selection: LabelAnnotation?
    var body: some View {
        VStack {
            CameraLabelPicker(
                selection: $selection,
                labels: .fakeLabels
            )
            Button {
                selection = nil
            } label: {
                Label {
                    Text(verbatim: "Reset to nil")
                } icon: {
                    Image(systemName: "undo")
                }
            }
        }
    }
}

#endif
