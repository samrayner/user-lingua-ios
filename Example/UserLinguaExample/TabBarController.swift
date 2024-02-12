// TabBarController.swift

import Foundation
import SwiftUI
import UIKit

final class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let tab2 = UIHostingController(rootView: ContentView())
        tab2.tabBarItem = UITabBarItem(title: String(localized: "ul_tab_bar_2_title"), image: nil, selectedImage: nil)

        viewControllers?.append(tab2)
    }
}
