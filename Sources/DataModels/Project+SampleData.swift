// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

#if DEBUG

extension Project {
    static let fake = Project(id: ProjectID(), title: "My Fake Project", createdAt: Date(), shareState: .notShared, labelNames: ["dog", "cat"])

    enum sampleData {
        static let animals = Project(id: ProjectID(), title: "My Fake Project", createdAt: Date(), shareState: .shareOwner, labelNames: ["dog", "cat"])

        static let empty = Project(id: ProjectID(), title: "🫗", createdAt: Date(), shareState: .notShared, labelNames: [])
        /// Project with has repeating unicode labels
        static let houses = Project(id: ProjectID(), title: "C̸̟̟̜͈̗̎̋́͒̍͛̄͆̃̈́̿͑̀́̌ͅr̸̢̧̛̦͙̫̥͖̞̙͆̿̾ä̶̛̪̺͈̇͂͒̅͋̋͘ͅz̴̨̰̹̤̘͈̪͍̯̘̹̑̾̽̔̔̈̎̂̇̽́́̚̚͜͝ý̵̢̡͚̻̯̤̯̭̦͉̲͎̪̈́̓́̈́̃̅̕͜ ̷̛̼̤͔̠͈̪͛̀̽͐̆̓̇̓͑H̴̰̊͊̌̅̆͑͆̈̓̈̾̌͠o̴͙̓͗͒͊̀͝u̴̟̐̆͛̈̋̍̚͠s̵͕͊̒̀́̅͋̚͜͠e̴̱͇̅̃̅̋s̴̰̦̹͓̜͎͚̱̜͔̠̄̉̅̑̅͐̌̄̿͊̏̚͠", createdAt: Date(), shareState: .notShared, labelNames: ["🏠", "🏚️", "⌂", "🏠", "🏚️", "⌂", "🏠", "🏚️", "⌂"])

        static func randomProject() -> Project {
            Project(id: ProjectID(), title: "Project \(Int.random(in: 0...1000))", createdAt: Date())
        }
    }
}

#endif
