//
//  CreateAccount.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI
import SwiftData

struct CreateAccount: View {
    
    @Environment(\.dismiss) var dismiss
    @AppStorage("accountGroupID") var selectedAccountsGroupID: Int = 0
    let currencies = Currencies.symbols
    @Query var accountGroups: [AccountGroup]
    
    var accountType: AccountType
    @State var budget: String = ""
    @State var remainder: String = ""
    @State var currency: String = "USD"
    @State var name: String = ""
    @State var gradualBudgetFilling: Bool = true
    
    var body: some View {
        Form {
            Section {
                
                TextField("Название счета", text: $name)
                
                if accountType == .expense || accountType == .earnings {
                    TextField("Бюджет", text: $budget)
                        .keyboardType(.decimalPad)
                } else {
                    TextField("Начальный баланс", text: $remainder)
                        .keyboardType(.decimalPad)
                }
                
                Toggle(isOn: $gradualBudgetFilling) {
                    Text("Плавное заполнение бюджета")
                }
                
                Picker("Валюта", selection: $currency) {
                    ForEach(currencies.keys.sorted(by: >), id: \.self) { currency in
                        Text(currency)
                    }
                }
            }
            Section {
                Button("Сохранить") {
                    createAccount()
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
    CreateAccount(accountType: .regular)
}
