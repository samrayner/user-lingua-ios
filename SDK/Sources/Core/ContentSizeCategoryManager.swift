// ContentSizeCategoryManager.swift

import Combine
import Dependencies
import Spyable
import UIKit

@Spyable
package protocol ContentSizeCategoryManagerProtocol {
    var systemPreferredContentSizeCategory: UIContentSizeCategory { get }
    func notifyDidChange(newValue: UIContentSizeCategory)
}

package final class ContentSizeCategoryManager: ContentSizeCategoryManagerProtocol {
    package private(set) var systemPreferredContentSizeCategory = UITraitCollection.current.preferredContentSizeCategory
    private var cancellables = Set<AnyCancellable>()

    package init() {
        NotificationCenter.default
            .publisher(for: UIContentSizeCategory.didChangeNotification)
            .filter { $0.userInfo?[UIContentSizeCategory.isUserLinguaNotificationUserInfoKey] == nil }
            .compactMap { $0.userInfo?[UIContentSizeCategory.newValueUserInfoKey] as? UIContentSizeCategory }
            .assign(to: \.systemPreferredContentSizeCategory, on: self)
            .store(in: &cancellables)
    }

    package func notifyDidChange(newValue: UIContentSizeCategory) {
        NotificationCenter.default.post(
            name: UIContentSizeCategory.didChangeNotification,
            object: nil,
            userInfo: [
                UIContentSizeCategory.newValueUserInfoKey: newValue,
                UIContentSizeCategory.isUserLinguaNotificationUserInfoKey: true
            ]
        )
    }
}

package enum ContentSizeCategoryManagerDependency: DependencyKey {
    package static let liveValue: any ContentSizeCategoryManagerProtocol = ContentSizeCategoryManager()
    package static let previewValue: any ContentSizeCategoryManagerProtocol = ContentSizeCategoryManagerProtocolSpy()
    package static let testValue: any ContentSizeCategoryManagerProtocol = ContentSizeCategoryManagerProtocolSpy()
}
