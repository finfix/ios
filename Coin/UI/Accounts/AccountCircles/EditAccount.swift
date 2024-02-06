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
    private var modelContext: ModelContext
    private var currencies: [Currency] = []
    @AppStorage("accountGroupID") var selectedAccountsGroupID: Int = 0
    @Bindable var account = Account()
    private var oldAccount = Account()
    private var accountPermissions = AccountPermissions()
    
    var mode: mode = .create
    
    init(_ account: Account) {
        self.init()
        mode = .update
        
        self.oldAccount = account
        self.account = modelContext.model(for: account.persistentModelID) as! Account
        self.accountPermissions = GetPermissions(account: account)
    }
    
    init(accountType: AccountType) {
        self.init()        
        mode = .create

        currencies = try! modelContext.fetch(FetchDescriptor<Currency>(sortBy: [SortDescriptor(\.isoCode)]))
        let accountGroups = try! modelContext.fetch(FetchDescriptor<AccountGroup>())
        
        _account = .init(wrappedValue: Account(
            accountGroup: accountGroups.first { $0.id == selectedAccountsGroupID }!,
            currency: currencies.first { $0.isoCode == "USD" }!,
            type: accountType
        ))
        self.accountPermissions = GetPermissions(account: account)
    }
    
    private init() {
        
        modelContext = ModelContext(container)
        modelContext.autosaveEnabled = false
    }
        
    var body: some View {
        Form {
            Section {
                
                TextField("Название счета", text: $account.name)
                               
                if accountPermissions.changeBudget {
                    TextField("Бюджет", value: $account.budgetAmount, format: .number)
                        .keyboardType(.decimalPad)
                }
                
                if accountPermissions.changeRemainder {
                    TextField(mode == .create ? "Начальный баланс" : "Баланс", value: $account.remainder, format: .number)
                        .keyboardType(.decimalPad)
                }
                
            }
            Section {
                
                Toggle("Учитывать ли счет в шапке", isOn: $account.accounting)
                if mode == .update {
                    Toggle("Видимость счета", isOn: $account.visible)
                }
                
                if accountPermissions.changeBudget {
                    Toggle("Плавное заполнение бюджета", isOn: $account.budgetGradualFilling)
                }
                
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
            account.id = try await AccountAPI().CreateAccount(req: CreateAccountReq(
                accountGroupID: account.accountGroup?.id ?? 0,
                accounting: account.accounting,
                budget: CreateAccountBudgetReq (
                    amount: account.budgetAmount,
                    gradualFilling: account.budgetGradualFilling
                ),
                currency: account.currency?.isoCode ?? "",
                iconID: 1,
                name: account.name,
                remainder: account.remainder != 0 ? account.remainder : nil,
                type: account.type.rawValue)
            )
            modelContext.insert(account)
            try modelContext.save()
        } catch {
            modelContext.rollback()
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
            try modelContext.save()
        } catch {
            modelContext.rollback()
            logger.error("\(error)")
            showErrorAlert("\(error)")
        }
    }
}

#Preview {
    EditAccount(accountType: .regular)
        .modelContainer(previewContainer)
}
