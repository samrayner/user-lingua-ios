import UIKit

extension UIButton {
    private static let notificationObservationAssociation = ObjectAssociation<NSObjectProtocol>()
    private static let unprocessedNormalTitleAssociation = ObjectAssociation<NSString>()
    private static let unprocessedHighlightedTitleAssociation = ObjectAssociation<NSString>()
    private static let unprocessedDisabledTitleAssociation = ObjectAssociation<NSString>()
    private static let unprocessedSelectedTitleAssociation = ObjectAssociation<NSString>()
    private static let unprocessedFocusedTitleAssociation = ObjectAssociation<NSString>()
    private static let unprocessedApplicationTitleAssociation = ObjectAssociation<NSString>()
    private static let unprocessedReservedTitleAssociation = ObjectAssociation<NSString>()
    
    var notificationObservation: NSObjectProtocol? {
        get { return Self.notificationObservationAssociation[self] }
        set { Self.notificationObservationAssociation[self] = newValue }
    }
    
    var unprocessedNormalTitle: String? {
        get { return Self.unprocessedNormalTitleAssociation[self] as String? }
        set { Self.unprocessedNormalTitleAssociation[self] = newValue as NSString? }
    }
    
    var unprocessedHighlightedTitle: String? {
        get { return Self.unprocessedHighlightedTitleAssociation[self] as String? }
        set { Self.unprocessedHighlightedTitleAssociation[self] = newValue as NSString? }
    }
    
    var unprocessedDisabledTitle: String? {
        get { return Self.unprocessedDisabledTitleAssociation[self] as String? }
        set { Self.unprocessedDisabledTitleAssociation[self] = newValue as NSString? }
    }
    
    var unprocessedSelectedTitle: String? {
        get { return Self.unprocessedSelectedTitleAssociation[self] as String? }
        set { Self.unprocessedSelectedTitleAssociation[self] = newValue as NSString? }
    }
    
    var unprocessedFocusedTitle: String? {
        get { return Self.unprocessedFocusedTitleAssociation[self] as String? }
        set { Self.unprocessedFocusedTitleAssociation[self] = newValue as NSString? }
    }
    
    var unprocessedApplicationTitle: String? {
        get { return Self.unprocessedApplicationTitleAssociation[self] as String? }
        set { Self.unprocessedApplicationTitleAssociation[self] = newValue as NSString? }
    }
    
    var unprocessedReservedTitle: String? {
        get { return Self.unprocessedReservedTitleAssociation[self] as String? }
        set { Self.unprocessedReservedTitleAssociation[self] = newValue as NSString? }
    }
    
    static func swizzle() {
        swizzle(
            original: #selector(didMoveToSuperview),
            with: #selector(swizzledDidMoveToSuperview)
        )
        
        swizzle(
            original: #selector(setTitle),
            with: #selector(swizzledSetTitle)
        )
    }
    
    @objc func swizzledSetTitle(_ title: String?, for state: State) {
        switch state {
        case .normal:
            unprocessedNormalTitle = title
        case .highlighted:
            unprocessedHighlightedTitle = title
        case .disabled:
            unprocessedDisabledTitle = title
        case .selected:
            unprocessedSelectedTitle = title
        case .focused:
            unprocessedFocusedTitle = title
        case .application:
            unprocessedApplicationTitle = title
        case .reserved:
            unprocessedReservedTitle = title
        default:
            swizzledSetTitle(title, for: state) //confusingly, calls the unswizzled method
            return
        }
        
        let processedString = title.map { UserLingua.shared.processString($0, localize: false) }
        swizzledSetTitle(processedString, for: state) //confusingly, calls the unswizzled method
    }
    
    @objc func swizzledDidMoveToSuperview() {
        swizzledDidMoveToSuperview() //confusingly, calls the unswizzled method
        guard notificationObservation == nil else { return }
        
        notificationObservation = NotificationCenter.default.addObserver(
            forName: .userLinguaObjectDidChange,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            self?.didFire(notification)
        }
    }
    
    @objc func didFire(_ notification: Notification) {
        //call the swizzled setTitle to re-evaluate the current title based on UserLingua's state
        
        let unprocessedTitle: String? = switch state {
        case .normal:
            unprocessedNormalTitle
        case .highlighted:
            unprocessedHighlightedTitle
        case .disabled:
            unprocessedDisabledTitle
        case .selected:
            unprocessedSelectedTitle
        case .focused:
            unprocessedFocusedTitle
        case .application:
            unprocessedApplicationTitle
        case .reserved:
            unprocessedReservedTitle
        default:
            nil
        }
        
        if unprocessedTitle != nil {
            setTitle(unprocessedTitle, for: state)
        }
    }
}
