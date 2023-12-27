// UserLinguaDisableable.swift

import UIKit

public protocol UserLinguaDisableable {
    var userLinguaDisabled: Bool { get }
}

extension UserLingua {
    public static func isDisabled(for uiView: UIResponder) -> Bool {
        var responder: UIResponder? = uiView
        while responder != nil {
            if let disableable = responder as? UserLinguaDisableable {
                return disableable.userLinguaDisabled
            }
            responder = responder?.next
        }
        return false
    }
}

public protocol UserLinguaDisabled: UserLinguaDisableable {}

extension UserLinguaDisabled {
    public var userLinguaDisabled: Bool { true }
}
