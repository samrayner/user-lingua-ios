//
//  ExchangeResponse.swift
//  PenguinPay
//
//  Created by Sam Rayner on 19/03/2021.
//

import Foundation

struct ExchangeRatesResponse: Decodable {
    let rates: [String: Double]
}
