// ContentSizeCategoryObserver.swift

import Combine
import Dependencies
import Spyable
import UIKit

@Spyable
package protocol ContentSizeCategoryObserverProtocol {
    var systemPreferredContentSizeCategory: UIContentSizeCategory { get }
}

package final class ContentSizeCategoryObserver: ContentSizeCategoryObserverProtocol {
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
}

package enum ContentSizeCategoryObserverDependency: DependencyKey {
    package static let liveValue: any ContentSizeCategoryObserverProtocol = ContentSizeCategoryObserver()
    package static let previewValue: any ContentSizeCategoryObserverProtocol = ContentSizeCategoryObserverProtocolSpy()
    package static let testValue: any ContentSizeCategoryObserverProtocol = ContentSizeCategoryObserverProtocolSpy()
}
