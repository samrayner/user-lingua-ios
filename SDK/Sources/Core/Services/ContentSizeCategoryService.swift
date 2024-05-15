// ContentSizeCategoryService.swift

import Combine
import Dependencies
import UIKit

// sourcery: AutoMockable
public protocol ContentSizeCategoryServiceProtocol {
    var systemContentSizeCategory: UIContentSizeCategory { get }
    var appContentSizeCategory: UIContentSizeCategory { get }
    func incrementAppContentSizeCategory()
    func decrementAppContentSizeCategory()
    func resetAppContentSizeCategory()
}

public final class ContentSizeCategoryService: ContentSizeCategoryServiceProtocol {
    public private(set) var systemContentSizeCategory = UITraitCollection.current.preferredContentSizeCategory
    public private(set) var appContentSizeCategory = UITraitCollection.current.preferredContentSizeCategory
    private var cancellables = Set<AnyCancellable>()

    public init() {
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

    public func incrementAppContentSizeCategory() {
        notifyDidChange(newValue: appContentSizeCategory.incremented())
    }

    public func decrementAppContentSizeCategory() {
        notifyDidChange(newValue: appContentSizeCategory.decremented())
    }

    public func resetAppContentSizeCategory() {
        notifyDidChange(newValue: systemContentSizeCategory)
    }
}

public enum ContentSizeCategoryServiceDependency: DependencyKey {
    public static let liveValue: any ContentSizeCategoryServiceProtocol = ContentSizeCategoryService()
    public static let previewValue: any ContentSizeCategoryServiceProtocol = ContentSizeCategoryServiceProtocolMock()
    public static let testValue: any ContentSizeCategoryServiceProtocol = ContentSizeCategoryServiceProtocolMock()
}
