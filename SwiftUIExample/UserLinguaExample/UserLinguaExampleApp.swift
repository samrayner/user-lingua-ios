// UserLinguaExampleApp.swift

import SwiftUI
import UserLingua
import UserLinguaTextOptIn

@main
struct UserLinguaExampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            NavigationView {
                PaymentView()
            }
        }
    }
}

final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let userLinguaConfig = UserLingua.Configuration(
        )
        UserLingua.shared.enable(config: userLinguaConfig)
        return true
    }
}
