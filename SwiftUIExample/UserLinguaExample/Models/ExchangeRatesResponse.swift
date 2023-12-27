// ExchangeRatesResponse.swift

import Foundation

struct ExchangeRatesResponse: Decodable {
    let rates: [String: Double]
}
