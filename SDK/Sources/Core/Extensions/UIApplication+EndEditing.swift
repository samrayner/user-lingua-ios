// UIApplication+EndEditing.swift

import Foundation
import UIKit

extension UIApplication {
    package func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
