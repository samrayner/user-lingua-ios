// ViewController.swift

import UIKit
import UserLingua

class ULDisabledButton: UIButton, UserLinguaDisableable {
    let userLinguaDisabled = true
}

class ULDisabledStackView: UIStackView, UserLinguaDisabled {}

class ViewController: UIViewController {
    @IBOutlet private var localizedLabel: UILabel!
    @IBOutlet private var localizedLabel2: UILabel!
    @IBOutlet private var unlocalizedLabel: UILabel!
    @IBOutlet private var button: UIButton!
    @IBOutlet private var disabledButton: UIButton!
    @IBOutlet private var disabledLabel: UILabel!
    @IBOutlet private var segmentedControl: UISegmentedControl!
    @IBOutlet private var textView: UITextView!
    @IBOutlet private var textField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        localizedLabel.text = Bundle.main.localizedString(forKey: "ul_label_text", value: nil, table: nil)
        localizedLabel2.text = Bundle.main.localizedString(forKey: "ul_label_text", value: nil, table: nil)
        unlocalizedLabel.text = "Unlocalized"
        button.setTitle(NSLocalizedString("ul_button_title_normal", comment: ""), for: .normal)
        disabledButton.setTitle(Bundle.main.localizedString(forKey: "ul_button_title_disabled", value: nil, table: nil), for: .normal)
        segmentedControl.setTitle(String(localized: "ul_segmented_control_1_title"), forSegmentAt: 0)
        segmentedControl.setTitle(String(localized: "ul_segmented_control_2_title"), forSegmentAt: 1)
        textView.text = String(localized: "ul_text_view_text")
        textField.placeholder = String(localized: LocalizedStringResource("ul_text_field_placeholder"))
        tabBarItem.title = String(localized: "ul_tab_bar_1_title")
        disabledLabel.text = String(localized: "ul_disabled_label_text")
    }
}
