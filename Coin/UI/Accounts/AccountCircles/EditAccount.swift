//
//  CreateAccount.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI
import SwiftData

enum mode {
    case create, update
}

struct EditAccount: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @AppStorage("accountGroupID") var selectedAccountsGroupID: Int = 0
    @State var account: Account
    var oldAccount: Account = Account()
    
    var mode: mode
    let currencies = Currencies.symbols
    var currencyFormatter = CurrencyFormatter()
    
    init(_ account: Account) {
        self.oldAccount = account
        _account = .init(wrappedValue: account)
        mode = .update
        numberFormatter = NumberFormatter()
        numberFormatter.currencySymbol = "&"
    }
    
    init(accountType: AccountType) {
        _account = .init(wrappedValue: Account(
                currency: "USD",
                type: accountType
            )
        )
        mode = .create
        numberFormatter = NumberFormatter()
        numberFormatter.currencySymbol = "&"
    }
    
    let numberFormatter: NumberFormatter
    
    var body: some View {
        Form {
            Section {
                
                TextField("Название счета", text: $account.name)
                
                TextField("Бюджет", value: $account.budget, format: .number)
                    .keyboardType(.decimalPad)
                
                TextField(mode == .create ? "Начальный баланс" : "Баланс", value: $account.remainder, format: .number)
                    .keyboardType(.decimalPad)
                
            }
            Section {
                
                if mode == .update {
                    Toggle("Видимость счета", isOn: $account.visible)
                }
                
                Toggle("Плавное заполнение бюджета", isOn: $account.gradualBudgetFilling)
                
                if mode == .create {
                    Picker("Валюта", selection: $account.currency) {
                        ForEach(currencies.keys.sorted(by: >), id: \.self) { currency in
                            Text(currency)
                        }
                    }
                }
            }
            Section {
                Button("Сохранить") {
                    dismiss()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    func createAccount() {
        Task {
            var budget: Double?
            var remainder: Double?
            
            if self.budget != "" {
                budget = Double(self.budget.replacingOccurrences(of: ",", with: "."))
            }
            
            if self.remainder != "" {
                remainder = Double(self.remainder.replacingOccurrences(of: ",", with: "."))
            }
            
            do {
                let id = try await AccountAPI().CreateAccount(req: CreateAccountReq(
                    accountGroupID: modelData.selectedAccountsGroupID,
                    accounting: true,
                    budget: budget,
                    currency: currency,
                    iconID: 1,
                    name: name,
                    remainder: remainder,
                    type: accountType.rawValue,
                    gradualBudgetFilling: gradualBudgetFilling)
                )
            } catch {
                debugLog(error)
            }
        }
    }
}

#Preview {
    EditAccount(accountType: .regular)
}
