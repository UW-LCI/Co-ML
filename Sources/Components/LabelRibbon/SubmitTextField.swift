// Copyright 2026 Apple Inc. All rights reserved.

import os.log
import SwiftUI

/// A TextField which submits but does not change a binding.  Has validation rule
struct SubmitTextField: View {
    let label: String
    @State private var dynamicLabel: String = ""
    let submit: (String) -> Void
    let isFocused: Bool

    init(label: String, isFocused: Bool, submit: @escaping (String) -> Void) {
        self.label = label
        self.isFocused = isFocused
        self.submit = submit
        self.dynamicLabel = dynamicLabel
    }

    var body: some View {

        TextField(String(localized: .labelName), text: $dynamicLabel)
            .onSubmit {
                submitLabelChangeIfAppropriate()
            }
            .onAppear {
                dynamicLabel = label
            }
            .onChange(of: label) { newLabel in
                if dynamicLabel == label {
                    // If the user has NOT edited the label yet, accept someone else's change.
                    os_log(.info, "Dynamic label changed from \(label) to \(newLabel)")
                    dynamicLabel = newLabel
                } else if dynamicLabel == newLabel {
                    // If the user edited the label and it committed, we expect the database to quickly return the new
                    // label, which is the same as the dynamic state.
                    os_log(.debug, "Acknowledging a change from \(label) to \(newLabel)")
                } else {
                    // The user is mid-editing - ignore remote changes.
                    os_log(.debug, "Ignoring change from \(label) to \(newLabel) during editing")
                }
            }
            .onChange(of: isFocused) { newFocusValue in
                // Handling of tap-out.
                if !newFocusValue {
                    submitLabelChangeIfAppropriate()
                }
            }
            .onDisappear {
                // Handling of back button press, or tab switch while editing.
                if isFocused {
                    submitLabelChangeIfAppropriate()
                }
            }
    }

    private func submitLabelChangeIfAppropriate() {
        let validLabel = dynamicLabel.validated(previous: label)
        if validLabel == label {
            if dynamicLabel != label {
                os_log(.info, "Reverting from \(dynamicLabel) to \(label)")
                dynamicLabel = label
            }
            return
        }
        os_log(.info, "Renaming label from \(label) to \(validLabel)")
        dynamicLabel = validLabel
        submit(validLabel)
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    VStack {
        SubmitTextField(label: "Field 1", isFocused: true) { newValue in
            print("Field 1 value updated to '\(newValue)'")
        }

        SubmitTextField(label: "Field 2", isFocused: false) { newValue in
            print("Field 2 value updated to '\(newValue)'")
        }

        Spacer()
    }
    .padding()
}

#endif
