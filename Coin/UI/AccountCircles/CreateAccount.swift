//
//  CreateAccount.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI

struct CreateAccount: View {
    
    @Binding var isOpeningFrame: Bool
    @Environment(ModelData.self) var modelData
    
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
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                } else {
                    TextField("Начальный баланс", text: $remainder)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                
                Toggle(isOn: $gradualBudgetFilling) {
                    Text("Плавное заполнение бюджета")
                }
                
                Picker("Валюта", selection: $currency) {
                    ForEach(modelData.currencies.keys.sorted(by: >), id: \.self) { currency in
                        Text(currency)
                            .tag(currency)
                    }
                }
            }
            Section {
                Button("Сохранить") {
                    createAccount()
                    isOpeningFrame = false
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
    CreateAccount(isOpeningFrame: .constant(true), accountType: .regular)
}
