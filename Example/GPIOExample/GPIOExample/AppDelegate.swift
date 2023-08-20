//
//  AppDelegate.swift
//  GPIOExample
//
//  Created by Akira Matsuda on 2023/08/20.
//

import Combine
import CombineExt
import Konashi
import os.log
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var cancellable = Set<AnyCancellable>()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        [
            MeshManager.sharedLogOutput,
            CentralManager.sharedLogOutput,
            KonashiPeripheral.sharedLogOutput,
            MeshNode.sharedLogOutput
        ].merge()
            .sink { log in
                os_log("%{public}@", log: log.osLog, type: log.osLogType, log.description)
            }.store(in: &cancellable)

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
