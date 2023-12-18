//
//  ContentView.swift
//  PenguinPay
//
//  Created by Sam Rayner on 19/03/2021.
//

import SwiftUI
import UserLingua

struct PaymentView: View {
    @StateObject var viewModel: PaymentViewModel = .init()
    @ObservedObject private(set) var userLingua = UserLingua.shared

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        let key = "payment.recipient.first_name"
        return VStack {
            Text("payment.recipient.section_title")
            Text(key)
            Text(key.prefix(999))
            Text("payment.recipient.section_title", tableName: "Localizable")
            Text("payment.recipient.section_title", tableName: "Localizable", bundle: .main)
            Text("payment.recipient.section_title", tableName: "Localizable", bundle: .main, comment: "Hi")
            Text("payment.recipient.section_title", bundle: .main)
            Text("payment.recipient.section_title", comment: "Hi")
            Text("payment.recipient.section_title", bundle: .main, comment: "Hi")
        }
        Form {
            Section(header: Text("payment.recipient.section_title").userLingua()) {
                TextField(
                    UL("payment.recipient.first_name"),
                    text: $viewModel.firstName
                )
                .autocapitalization(.words)
                .disableAutocorrection(true)

                TextField(
                    UL("payment.recipient.last_name"),
                    text: $viewModel.lastName
                )
                .autocapitalization(.words)
                .disableAutocorrection(true)

                Picker(
                    UL("payment.recipient.country"),
                    selection: $viewModel.country
                ) {
                    ForEach(Country.allCases, id: \.self) {
                        Text($0.localizedName)
                    }
                }

                HStack {
                    Text("+\(viewModel.country.phonePrefix)")

                    TextField(
                        UL("payment.recipient.phone_number"),
                        text: $viewModel.phoneNumber
                    )
                    .keyboardType(.numberPad)
                }
            }

            Section(header: Text("payment.amount.section_title")) {
                HStack {
                    Text("$")

                    TextField(
                        UL("payment.amount.placeholder"),
                        text: $viewModel.binaryAmountIn
                    )
                    .keyboardType(.numberPad)
                }
            }

            if !viewModel.exchangeRates.isEmpty {
                if viewModel.allFieldsValid {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("payment.preview.recipient \(viewModel.firstName) \(viewModel.lastName)")
                            .font(.system(size: 18))
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)

                        Text("\(viewModel.country.currencyCode) \(viewModel.binaryAmountOut)")
                            .font(.system(size: 20, weight: .bold))
                            .minimumScaleFactor(0.1)
                    }
                    .padding(.vertical)
                } else {
                    Text("payment.preview.missing_required_info")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Button(UL("payment.submit"), action: viewModel.submit)
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .disabled(!viewModel.allFieldsValid)
            }

            Section(header: Text("payment.exchange_rates.section_title")) {
                if viewModel.isFetchingExchangeRates {
                    ProgressView()
                } else if let lastUpdate = viewModel.exchangeRatesUpdatedAt {
                    Text(LocalizedStringKey("payment.exchange_rates.updated_at \(dateFormatter.string(from: lastUpdate))"))
                } else {
                    Text("payment.exchange_rates.fetch_error")
                        .foregroundColor(.red)
                }

                Button(UL("payment.exchange_rates.update"), action: viewModel.fetchExchangeRates)
                    .disabled(viewModel.isFetchingExchangeRates)
            }
        }
        .onAppear(perform: viewModel.fetchExchangeRates)
        .navigationTitle(UL("payment.title"))
        .alert(isPresented: $viewModel.showingConfirmation) {
            Alert(
                title: Text("payment.confirmation.title"),
                message: Text("payment.confirmation.message \(viewModel.country.currencyCode) \(viewModel.binaryAmountOut) \(viewModel.firstName) \(viewModel.lastName)"),
                dismissButton: .default(Text("global.ok"))
            )
        }
    }
}

struct PaymentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PaymentView()
        }
    }
}
