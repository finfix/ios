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
    @Query var currencies: [Currency]
    @AppStorage("accountGroupID") var selectedAccountsGroupID: Int = 0
    @State var account: Account
    var oldAccount: Account = Account()
    
    var mode: mode
    
    init(_ account: Account) {
        mode = .update
        self.oldAccount = account
        _account = .init(wrappedValue: account)
    }
    
    init(accountType: AccountType) {
        mode = .create
        _account = .init(wrappedValue: Account(
                currency: "USD",
                type: accountType
            )
        )
    }
        
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
                        ForEach(currencies) { currency in
                            Text(currency.isoCode)
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
            var req = CreateAccountReq(
                accountGroupID: UInt32(selectedAccountsGroupID),
                accounting: true,
                currency: account.currency?.isoCode ?? "",
                iconID: 1,
                name: account.name,
                type: account.type.rawValue,
                gradualBudgetFilling: account.gradualBudgetFilling
            )
            
            if account.budget != 0 {
                req.budget = account.budget
            }
            
            if account.remainder != 0 {
                req.budget = account.remainder
            }
            
            do {
                let id = try await AccountAPI().CreateAccount(req: req)
            } catch {
                debugLog(error)
            }
        }
    }
}

#Preview {
    EditAccount(accountType: .regular)
        .modelContainer(previewContainer)
}
