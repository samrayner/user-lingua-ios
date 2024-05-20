// ContentSizeCategoryService.swift

import Combine
import UIKit

// sourcery: AutoMockable
package protocol ContentSizeCategoryServiceProtocol {
    var systemContentSizeCategory: UIContentSizeCategory { get }
    var appContentSizeCategory: UIContentSizeCategory { get }
    func incrementAppContentSizeCategory()
    func decrementAppContentSizeCategory()
    func resetAppContentSizeCategory()
}

package final class ContentSizeCategoryService: ContentSizeCategoryServiceProtocol {
    package private(set) var systemContentSizeCategory = UITraitCollection.current.preferredContentSizeCategory
    package private(set) var appContentSizeCategory = UITraitCollection.current.preferredContentSizeCategory
    private var cancellables = Set<AnyCancellable>()

    package init() {
        NotificationCenter.default
            .publisher(for: UIContentSizeCategory.didChangeNotification)
            .sink { [weak self] in
                guard let contentSizeCategory = $0.userInfo?[UIContentSizeCategory.newValueUserInfoKey] as? UIContentSizeCategory
                else { return }

                let isUserLinguaNotification = $0.userInfo?[UIContentSizeCategory.isUserLinguaNotificationUserInfoKey] as? Bool == true

                if isUserLinguaNotification {
                    self?.appContentSizeCategory = contentSizeCategory
                } else {
                    self?.systemContentSizeCategory = contentSizeCategory
                }
            }
            .store(in: &cancellables)
    }

    private func notifyDidChange(newValue: UIContentSizeCategory) {
        NotificationCenter.default.post(
            name: UIContentSizeCategory.didChangeNotification,
            object: nil,
            userInfo: [
                UIContentSizeCategory.newValueUserInfoKey: newValue,
                UIContentSizeCategory.isUserLinguaNotificationUserInfoKey: true
            ]
        )
    }

    package func incrementAppContentSizeCategory() {
        notifyDidChange(newValue: appContentSizeCategory.incremented())
    }

    package func decrementAppContentSizeCategory() {
        notifyDidChange(newValue: appContentSizeCategory.decremented())
    }

    package func resetAppContentSizeCategory() {
        notifyDidChange(newValue: systemContentSizeCategory)
    }
}
