//
//  CreateAccount.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "Coin", category: "EditAccount")

enum mode {
    case create, update
}

struct EditAccount: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query var currencies: [Currency]
    @Query var accountGroups: [AccountGroup]
    @AppStorage("accountGroupID") var selectedAccountsGroupID: Int = 0
    @Bindable var account: Account
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
                id: UInt32.random(in: 10000..<10000000),
                type: accountType
            )
        )
    }
        
    var body: some View {
        Form {
            Section {
                
                TextField("Название счета", text: $account.name)
                
                Text(account.accountGroup?.name ?? "")
                                
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
        .navigationTitle(mode == .create ? "Cоздание счета" : "Изменение счета")
    }
    
    func createAccount() async {
        do {
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
            try modelContext.save()
        } catch {
            modelContext.rollback()
            logger.error("\(error)")
            showErrorAlert(error.localizedDescription)
        }
    }
    
    func updateAccount() async {
        do {
            try await AccountAPI().UpdateAccount(req: UpdateAccountReq(
                id: account.id,
                accounting: account.accounting,
                budget: account.budget,
                name: account.name,
                remainder: account.remainder,
                visible: account.visible,
                gradualBudgetFilling: account.gradualBudgetFilling)
            )
            try modelContext.save()
        } catch {
            modelContext.rollback()
            logger.error("\(error)")
            showErrorAlert(error.localizedDescription)
        }
    }
}

#Preview {
    EditAccount(accountType: .regular)
        .modelContainer(previewContainer)
}
