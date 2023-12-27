// Country.swift

import Foundation
import SwiftUI

struct Country: Hashable {
    static let kenya = Self(
        name: "country.kenya",
        currencyCode: "KES",
        phonePrefix: "254",
        phoneSuffixPartLengths: [3, 6]
    )

    static let nigeria = Self(
        name: "country.nigeria",
        currencyCode: "NGN",
        phonePrefix: "234",
        phoneSuffixPartLengths: [3, 4]
    )

    static let tanzania = Self(
        name: "country.tanzania",
        currencyCode: "TZS",
        phonePrefix: "255",
        phoneSuffixPartLengths: [3, 3, 3]
    )

    static let uganda = Self(
        name: "country.uganda",
        currencyCode: "UGX",
        phonePrefix: "256",
        phoneSuffixPartLengths: [3, 4]
    )

    static var allCases: [Country] {
        [.kenya, .nigeria, .tanzania, .uganda]
    }

    let name: String
    let currencyCode: String
    let phonePrefix: String
    let phoneSuffixPartLengths: [Int]

    var localizedName: LocalizedStringKey {
        .init(name)
    }

    var validPhoneNumberLength: Int {
        phoneSuffixPartLengths.reduce(phoneSuffixPartLengths.count - 1, +)
    }
}
