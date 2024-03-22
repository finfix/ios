//
//  CreateAccount.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "EditAccount")

enum mode {
    case create, update
}

struct EditAccount: View {
    
    @Environment(\.dismiss) var dismiss
    private var currencies: [Currency] = []
    @AppStorage("accountGroupID") var selectedAccountsGroupID: Int = 0
    @State var account = Account()
    private var oldAccount = Account()
    private var accountPermissions = AccountPermissions()
    
    var mode: mode = .create
    
    init(_ account: Account) {
        mode = .update
        
        self.oldAccount = account
        self.accountPermissions = GetPermissions(account: account)
    }
    
    init(accountType: AccountType) {
        mode = .create

        let accountGroups = [AccountGroup]()
        self.accountPermissions = GetPermissions(account: account)
    }
        
    var body: some View {
        Form {
            Section {
                
                TextField("Название счета", text: $account.name)
                
                if accountPermissions.changeRemainder {
                    TextField(mode == .create ? "Начальный баланс" : "Баланс", value: $account.remainder, format: .number)
                        .keyboardType(.decimalPad)
                }
                
            }
            
            if accountPermissions.changeBudget {
                Section(header: Text("Бюджет")) {
                    TextField("Бюджет", value: $account.budgetAmount, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Фиксированная сумма", value: $account.budgetFixedSum, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Отступ в днях", value: $account.budgetDaysOffset, format: .number)
                        .keyboardType(.numberPad)
                    Toggle("Плавное заполнение бюджета", isOn: $account.budgetGradualFilling)
                }
            }
            
            Section {
                
                Toggle("Учитывать ли счет в шапке", isOn: $account.accounting)
                if mode == .update {
                    Toggle("Видимость счета", isOn: $account.visible)
                }
                
                
                
                if mode == .create {
//                    Picker("Валюта", selection: $account.currency) {
//                        ForEach(currencies) { currency in
//                            Text(currency.isoCode)
//                                .tag(currency as Currency?)
//                        }
//                    }
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
            account.id = try await AccountAPI().CreateAccount(req: CreateAccountReq(
                accountGroupID: account.accountGroup.id,
                accounting: account.accounting,
                budget: CreateAccountBudgetReq (
                    amount: account.budgetAmount,
                    gradualFilling: account.budgetGradualFilling
                ),
                currency: account.currency.code,
                iconID: 1,
                name: account.name,
                remainder: account.remainder != 0 ? account.remainder : nil,
                type: account.type.rawValue)
            )
        } catch {
            logger.error("\(error)")
            showErrorAlert("\(error)")
        }
    }
    
    func updateAccount() async {
        do {
            try await AccountAPI().UpdateAccount(req: UpdateAccountReq(
                id: account.id,
                accounting: oldAccount.accounting != account.accounting ? account.accounting : nil,
                name: oldAccount.name != account.name ? account.name : nil, 
                remainder: oldAccount.remainder != account.remainder ? account.remainder : nil, 
                visible: oldAccount.visible != account.visible ? account.visible : nil,
                budget: UpdateBudgetReq(
                    amount: oldAccount.budgetAmount != account.budgetAmount ? account.budgetAmount : nil,
                    fixedSum: oldAccount.budgetFixedSum != account.budgetFixedSum ? account.budgetFixedSum : nil,
                    daysOffset: oldAccount.budgetDaysOffset != account.budgetDaysOffset ? account.budgetDaysOffset : nil,
                    gradualFilling: oldAccount.budgetGradualFilling != account.budgetGradualFilling ? account.budgetGradualFilling : nil)
            ))
        } catch {
            logger.error("\(error)")
            showErrorAlert("\(error)")
        }
    }
}

#Preview {
    EditAccount(accountType: .regular)
}
