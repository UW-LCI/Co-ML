// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct DataSavingView: View {

    @Binding var selectedLocation: DataType

    var body: some View {
        Section {
            List {
                Picker(String(localized: .saveTo),
                       selection: $selectedLocation) {
                    ForEach(DataType.allCases) { location in
                        Text(location.purposeString.capitalized).tag(location)
                    }
                }
            }
            .listRowBackground(Color(UIColor.tertiarySystemBackground))
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    DataSavingView(
        selectedLocation: .constant(.testing)
    )
}

#endif
