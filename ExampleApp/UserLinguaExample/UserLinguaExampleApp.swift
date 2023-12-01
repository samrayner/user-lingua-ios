//
//  UserLinguaExampleApp.swift
//  UserLinguaExample
//
//  Created by Sam Rayner on 06/04/2023.
//

import SwiftUI
import UserLingua

@main
struct UserLinguaExampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                PaymentView()
            }
            .userLinguaRootView()
        }
    }
}

//extension Text: UserLinguaText {}

final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let userLinguaConfig = UserLingua.Configuration(
        )
        UserLingua.shared.enable(config: userLinguaConfig)
        return true
    }
}
