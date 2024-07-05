// AllDependencies.swift

import Foundation

// sourcery: AutoMockable
public protocol AllDependencies {
    var appViewModel: UserLinguaObservable { get }
    var notificationCenter: NotificationCenter { get }
    var deviceOrientationObservable: DeviceOrientationObservable { get }
    var contentSizeCategoryService: ContentSizeCategoryServiceProtocol { get }
    var stringExtractor: any StringExtractorProtocol { get }
    var stringRecognizer: any StringRecognizerProtocol { get }
    var stringsRepository: any StringsRepositoryProtocol { get }
    var suggestionsRepository: any SuggestionsRepositoryProtocol { get }
    var windowService: any WindowServiceProtocol { get }
    var swizzler: any SwizzlerProtocol { get }
}

public final class LiveDependencies: AllDependencies {
    public private(set) lazy var appViewModel: UserLinguaObservable = .init()
    public private(set) lazy var notificationCenter: NotificationCenter = .default
    public private(set) lazy var deviceOrientationObservable: DeviceOrientationObservable = DeviceOrientationObservable()
    public private(set) lazy var contentSizeCategoryService: ContentSizeCategoryServiceProtocol = ContentSizeCategoryService()
    public private(set) lazy var stringExtractor: any StringExtractorProtocol = StringExtractor()
    public private(set) lazy var stringsRepository: any StringsRepositoryProtocol = StringsRepository()
    public private(set) lazy var stringRecognizer: any StringRecognizerProtocol = StringRecognizer(stringsRepository: stringsRepository)
    public private(set) lazy var suggestionsRepository: any SuggestionsRepositoryProtocol = SuggestionsRepository()
    public private(set) lazy var windowService: any WindowServiceProtocol = WindowService()
    public let swizzler: any SwizzlerProtocol

    public init(swizzler: any SwizzlerProtocol) {
        self.swizzler = swizzler
    }
}
