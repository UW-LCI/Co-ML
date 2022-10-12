// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct ExportUnavailableView: View {
    var body: some View {
        VStack {
            Text(.modelExportUnavailable)
                .font(.title)
                .padding(.bottom)

            Text(.youCanExportACoreMlModelAfterYourModelIsTrained)
        }
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    ExportUnavailableView()
}

#endif
