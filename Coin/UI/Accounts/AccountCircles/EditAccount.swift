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
                                .tag(currency as Currency?)
                        }
                    }
                }
            }
            Section {
                Button("Сохранить") {
                    Task {
                        dismiss()
                        switch mode {
                        case .create:
                            await createAccount()
                        case .update:
                            await updateAccount()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    func createAccount() async {
        do {
            modelContext.insert(account)
            let id = try await AccountAPI().CreateAccount(req: CreateAccountReq(
                accountGroupID: UInt32(selectedAccountsGroupID),
                accounting: true,
                budget: account.budget != 0 ? account.budget : nil,
                currency: account.currency?.isoCode ?? "",
                iconID: 1,
                name: account.name,
                remainder: account.remainder != 0 ? account.remainder : nil,
                type: account.type.rawValue,
                gradualBudgetFilling: account.gradualBudgetFilling)
            )
            account.id = id
        } catch {
            debugLog(error)
            showErrorAlert(error.localizedDescription)
        }
    }
    
    func updateAccount() async {
        do {
            try await AccountAPI().UpdateAccount(req: UpdateAccountReq(
                id: account.id,
                accounting: oldAccount.accounting != account.accounting ? account.accounting : nil,
                budget: oldAccount.budget != account.budget ? account.budget : nil,
                name: oldAccount.name != account.name ? account.name : nil,
                remainder: oldAccount.remainder != account.remainder ? account.remainder : nil,
                visible: oldAccount.visible != account.visible ? account.visible : nil,
                gradualBudgetFilling: oldAccount.gradualBudgetFilling != account.gradualBudgetFilling ? account.gradualBudgetFilling : nil)
            )
        } catch {
            debugLog(error)
            showErrorAlert(error.localizedDescription)
        }
    }
}

#Preview {
    EditAccount(accountType: .regular)
        .modelContainer(previewContainer)
}
