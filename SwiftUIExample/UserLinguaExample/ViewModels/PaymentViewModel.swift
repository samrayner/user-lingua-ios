//
//  PaymentViewModel.swift
//  PenguinPay
//
//  Created by Sam Rayner on 19/03/2021.
//

import Foundation
import Combine

final class PaymentViewModel: ObservableObject {
    @Published var firstName: String = "" {
        didSet { format(\.firstName, with: formatName) }
    }

    @Published var lastName: String = "" {
        didSet { format(\.lastName, with: formatName) }
    }

    @Published var country: Country = .kenya {
        didSet { format(\.phoneNumber, with: formatPhoneNumber) }
    }

    @Published var phoneNumber: String = "" {
        didSet { format(\.phoneNumber, with: formatPhoneNumber) }
    }

    @Published var binaryAmountIn: String = "" {
        didSet { format(\.binaryAmountIn, with: formatBinary) }
    }

    @Published var binaryAmountOut: String = ""

    @Published var isFetchingExchangeRates = false

    @Published var exchangeRates: [String: Double] = [:]

    @Published var showingConfirmation = false

    var exchangeRatesUpdatedAt: Date?

    private let apiAppId = "bd0d75d47d774882ab34e3e56448c83e"
    private let requestPublisher: (URL) -> AnyPublisher<Data, URLError>

    var allFieldsValid: Bool {
        [firstName, lastName, binaryAmountIn, phoneNumber].allSatisfy { !$0.isEmpty }
        && phoneNumber.count == country.validPhoneNumberLength
    }

    private static func defaultRequestPublisher(url: URL) -> AnyPublisher<Data, URLError> {
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    init(requestPublisher: @escaping (URL) -> AnyPublisher<Data, URLError> = defaultRequestPublisher) {
        self.requestPublisher = requestPublisher

        $binaryAmountIn
            .merge(
                //recalculate if exchange rates change
                with: $exchangeRates.map { _ in self.binaryAmountIn }
            )
            .compactMap { binary in
                //convert binary String to Int
                Int(binary, radix: 2)
            }
            .compactMap { [weak self] amountIn in
                //echange using exchange rate if it exists
                self?.exchangeAmount(amountIn)
            }
            .compactMap { amountOut in
                //convert Int back to binary String
                String(amountOut, radix: 2)
            }
            .assign(to: &$binaryAmountOut)
    }

    func submit() {
        showingConfirmation = true
    }

    func fetchExchangeRates() {
        let countryCodeList = Country.allCases.map(\.currencyCode).joined(separator: ",")

        guard let url = URL(
            string: "https://openexchangerates.org/api/latest.json?app_id=\(apiAppId)&base=USD&symbols=\(countryCodeList)"
        ) else { return }

        isFetchingExchangeRates = true
        return requestPublisher(url)
            .decode(type: ExchangeRatesResponse.self, decoder: JSONDecoder())
            .map(\.rates)
            .replaceError(with: [:])
            .handleEvents(
                receiveOutput: { [weak self] in
                    guard !$0.isEmpty else { return }
                    self?.exchangeRatesUpdatedAt = Date()
                },
                receiveCompletion: { [weak self] _ in
                    self?.isFetchingExchangeRates = false
                }
            )
            .assign(to: &$exchangeRates)
    }

    private func exchangeAmount(_ amount: Int) -> Int? {
        guard let rate = exchangeRates[country.currencyCode] else { return nil }
        return Int(Double(amount) * rate)
    }

    private func format<Value: Equatable>(
        _ keyPath: ReferenceWritableKeyPath<PaymentViewModel, Value>,
        with format: (Value) -> Value
    ) {
        let currentValue = self[keyPath: keyPath]
        let formatted = format(currentValue)
        guard currentValue != formatted else { return }
        self[keyPath: keyPath] = formatted
    }

    private func formatName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func formatBinary(_ value: String) -> String {
        value
            //limit length so integer value < Int.max
            .prefix(18)
            //remove all characters that aren't 0 or 1
            .replacingOccurrences(
                of: #"[^01]"#,
                with: "",
                options: .regularExpression
            )
    }

    private func formatPhoneNumber(_ value: String) -> String {
        //remove all non-digit characters
        var phoneNumber = value.replacingOccurrences(
            of: #"[^\d]"#,
            with: "",
            options: .regularExpression
        )

        //chunk and limit length based on country phone number format
        return country.phoneSuffixPartLengths.compactMap { length in
            let part = phoneNumber.prefix(length)
            guard !part.isEmpty else { return nil }
            phoneNumber.removeFirst(min(length, phoneNumber.count))
            return String(part)
        }.joined(separator: " ")
    }
}
