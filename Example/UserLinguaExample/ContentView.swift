// ContentView.swift

import Foundation
import SwiftUI
import UserLingua

@UserLingua
struct ContentView: View {
    private enum PickerItem: String {
        case one = "ul_segmented_control_1_title"
    }

    @State private var selectedPickerItem: PickerItem = .one
    @State private var textFieldText = ""

    var body: some View {
        ScrollView {
            VStack {
                Text(String(format: NSLocalizedString("ul_args_test", comment: ""), "Sam", 33))

                Text("ul_label_text")

                Text("Unlocalized label".description)

                VStack {
                    Text("ul_disabled_label_text")
                }
                .userLinguaDisabled()

                Button(UL("ul_button_title_normal")) {}

                Picker("ul_label_text", selection: $selectedPickerItem) {
                    Text(LocalizedStringKey(selectedPickerItem.rawValue))
                }
                .pickerStyle(.segmented)

                TextField("ul_text_field_placeholder", text: $textFieldText)
            }
        }
    }
}
