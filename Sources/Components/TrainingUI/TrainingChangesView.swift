// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct TrainingChangesView: View {
    let changes: [ProjectModelInfo.Change]

    var body: some View {
        VStack(alignment: .leading, spacing: 7.0) {
            ForEach(changes) {
                TrainingChangeLabel(changes: $0)
            }
        }
        .font(.body)
        .fontWeight(.semibold)
    }
}

private struct TrainingChangeLabel: View {
    let changes: ProjectModelInfo.Change
    var body: some View {
        switch changes {
        case let .labelAdded(labelString):
            Label {
                Text(.theLabelWasAdded(labelString))
            } icon: {
                Image(systemName: "plus.circle.fill")
                    .renderingMode(.template)
                    .foregroundColor(.green)
            }

        case let .labelDeleted(labelString):
            Label {
                Text(.theLabelWasDeleted(labelString))
            } icon: {
                Image(systemName: "minus.circle.fill")
                    .renderingMode(.template)
                    .foregroundColor(.red)
            }

        case let .labelRenamed(oldLabelString, newLabelString):
            Label {
                Text(.theLabelWasRenamedTo(oldLabelString, newLabelString))
            } icon: {
                Image(systemName: "tag.circle.fill")
                    .renderingMode(.template)
                    .foregroundColor(.blue)
            }

        case let .samplesChanged(addedSampleCount, removedSampleCount, labelString):
            TrainingSamplesChangedLabel(
                addedSampleCount: addedSampleCount,
                removedSampleCount: removedSampleCount,
                labelString: labelString
            )
        }
    }
}

private struct TrainingSamplesChangedLabel: View {
    let addedSampleCount: Int
    let removedSampleCount: Int
    let labelString: String

    init(addedSampleCount: Int, removedSampleCount: Int, labelString: String) {
        assert(addedSampleCount + removedSampleCount > 0, "Added or removed sample required")
        self.addedSampleCount = addedSampleCount
        self.removedSampleCount = removedSampleCount
        self.labelString = labelString
    }

    var body: some View {
        if addedSampleCount > 0 {
            if removedSampleCount > 0 {
                Label {
                    Text(.imagesWereAddedToLabelAndRemoved(arg1: addedSampleCount, labelString, removedSampleCount))
                } icon: {
                    Image(systemName: "plusminus.circle.fill")
                        .renderingMode(.template)
                        .foregroundColor(.blue)
                }
            } else {
                Label {
                    Text(.imagesWereAddedToLabel(addedSampleCount, labelString))
                } icon: {
                    Image(systemName: "plus.circle.fill")
                        .renderingMode(.template)
                        .foregroundColor(.green)
                }
            }
        } else {
            Label {
                Text(.imagesWereRemovedFromLabel(removedSampleCount, labelString))
            } icon: {
                Image(systemName: "minus.circle.fill")
                    .renderingMode(.template)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    TrainingChangesView(
        changes: .fakeProjectChanges
    )
}

#endif
