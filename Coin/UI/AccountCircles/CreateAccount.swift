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
    
    var body: some View {
        
        VStack {
            Form {
                TextField("Название счета", text: $name)
                
                if accountType == .expense || accountType == .earnings {
                    TextField("Бюджет", text: $budget)
                        .keyboardType(.decimalPad)
                } else {
                    TextField("Начальный баланс", text: $remainder)
                        .keyboardType(.decimalPad)
                }
                
                TextField("Валюта", text: $currency)
            }
            Spacer()
            
            Button {
                createAccount()
                isOpeningFrame = false
            } label: {
                Text("Сохранить")
            }
            .padding()
        }
    }
    
    func createAccount() {
        
        var budget: Double?
        var remainder: Double?
        
        if self.budget != "" {
            budget = Double(self.budget.replacingOccurrences(of: ",", with: "."))
        }
        
        if self.remainder != "" {
            remainder = Double(self.remainder.replacingOccurrences(of: ",", with: "."))
        }
                
        AccountAPI().CreateAccount(req: CreateAccountReq(
            accountGroupID: modelData.selectedAccountsGroupID,
            accounting: true,
            budget: budget,
            currency: currency,
            iconID: 1,
            name: name,
            remainder: remainder,
            type: accountType.rawValue)) { model, error in
                if let err = error {
                    showErrorAlert(error: err)
                }
                if let response = model {
                    modelData.accounts.append(Account(
                        id: response.id,
                        accountGroupID: modelData.selectedAccountsGroupID,
                        accounting: true,
                        budget: budget ?? 0,
                        currency: currency,
                        iconID: 1,
                        name: name,
                        remainder: remainder ?? 0,
                        type: accountType,
                        visible: true))
                }
            }
    }
}

#Preview {
    CreateAccount(isOpeningFrame: .constant(true), accountType: .regular)
}
