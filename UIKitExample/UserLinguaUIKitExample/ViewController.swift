// ViewController.swift

import UIKit
import UserLingua

class ULDisabledButton: UIButton, UserLinguaDisableable {
    let userLinguaDisabled = true
}

class ULDisabledStackView: UIStackView, UserLinguaDisabled {}

class ViewController: UIViewController {
    @IBOutlet private var localizedLabel: UILabel!
    @IBOutlet private var unlocalizedLabel: UILabel!
    @IBOutlet private var button: ULDisabledButton!
    @IBOutlet private var disabledStackView: ULDisabledStackView!
    @IBOutlet private var disabledLabel: UILabel!
    @IBOutlet private var segmentedControl: UISegmentedControl!
    @IBOutlet private var textView: UITextView!
    @IBOutlet private var textField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        localizedLabel.text = Bundle.main.localizedString(forKey: "ul_label_text", value: nil, table: nil)
        unlocalizedLabel.text = "Unlocalized"
        button.setTitle(NSLocalizedString("ul_button_title_normal", comment: ""), for: .normal)
        button.setTitle(Bundle.main.localizedString(forKey: "ul_button_title_selected", value: nil, table: nil), for: .selected)
        segmentedControl.setTitle(String(localized: "ul_segmented_control_1_title"), forSegmentAt: 0)
        segmentedControl.setTitle(String(localized: "ul_segmented_control_2_title"), forSegmentAt: 1)
        textView.text = String(localized: "ul_text_view_text")
        // textField.text = NSLocalizedString("text_field_text", comment: "")
        textField.placeholder = String(localized: LocalizedStringResource("ul_text_field_placeholder"))
        tabBarItem.title = String(localized: "ul_tab_bar_1_title")
        disabledLabel.text = String(localized: "ul_disabled_label_text")
    }
}
