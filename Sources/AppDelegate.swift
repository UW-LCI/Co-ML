// Copyright 2026 Apple Inc. All rights reserved.

import UIKit
import CloudKit
import os.log

public class AppDelegate: NSObject, UIApplicationDelegate {
    // setup scene delegate
    public func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    // called when CKShare link is tapped and app is running or suspended
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        /**
         TODO
         Two things need to happen here:
         1) the share needs to be added to the user's CloudKit container
         2) once it's been added we need to trigger a refresh of the project view so the project appears

         The code below accomplishes (1) but not (2).
         */
        CoreDataDatabaseStorageService.shared.acceptShareInvitations(cloudKitShareMetadata: cloudKitShareMetadata)
    }
}
