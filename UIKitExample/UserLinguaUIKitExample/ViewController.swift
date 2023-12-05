//
//  ViewController.swift
//  UserLinguaUIKitExample
//
//  Created by Sam Rayner on 05/12/2023.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet private(set) var localizedLabel: UILabel!
    @IBOutlet private(set) var unlocalizedLabel: UILabel!
    @IBOutlet private(set) var button: UIButton!
    @IBOutlet private(set) var segmentedControl: UISegmentedControl!
    @IBOutlet private(set) var textView: UITextView!
    @IBOutlet private(set) var textField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        localizedLabel.text = Bundle.main.localizedString(forKey: "ul_label_text", value: nil, table: nil)
        unlocalizedLabel.text = "Unlocalized"
        button.setTitle(NSLocalizedString("ul_button_title_normal", comment: ""), for: .normal)
        button.setTitle(Bundle.main.localizedString(forKey: "ul_button_title_selected", value: nil, table: nil), for: .selected)
        segmentedControl.setTitle(String(localized: "ul_segmented_control_1_title"), forSegmentAt: 0)
        segmentedControl.setTitle(String(localized: "ul_segmented_control_2_title"), forSegmentAt: 1)
        textView.text = String(localized: "ul_text_view_text")
        //textField.text = NSLocalizedString("text_field_text", comment: "")
        textField.placeholder = String(localized: LocalizedStringResource("ul_text_field_placeholder"))
        tabBarItem.title = String(localized: "ul_tab_bar_1_title")
    }
}
