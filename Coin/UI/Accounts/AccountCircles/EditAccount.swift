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
    @Bindable var account: Account
    var oldAccount: Account = Account()
    
    var mode: mode
    
    init(_ account: Account) {
        self.init()
        mode = .update
        
        self.oldAccount = account
        self.account = modelContext.model(for: account.persistentModelID) as! Account
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
    }
    
    private init() {
        modelContext = ModelContext(container)
        modelContext.autosaveEnabled = false
        mode = .create
        account = Account()
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
        .navigationTitle(mode == .create ? "Cоздание счета" : "Изменение счета")
    }
    
    func createAccount() async {
        do {
            account.id = try await AccountAPI().CreateAccount(req: CreateAccountReq(
                accountGroupID: account.accountGroup?.id ?? 0,
                accounting: true,
                budget: account.budget != 0 ? account.budget : nil,
                currency: account.currency?.isoCode ?? "",
                iconID: 1,
                name: account.name,
                remainder: account.remainder != 0 ? account.remainder : nil,
                type: account.type.rawValue,
                gradualBudgetFilling: account.gradualBudgetFilling)
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
                budget: oldAccount.budget != account.budget ? account.budget : nil,
                name: oldAccount.name != account.name ? account.name : nil,
                remainder: oldAccount.remainder != account.remainder ? account.remainder : nil,
                visible: oldAccount.visible != account.visible ? account.visible : nil,
                gradualBudgetFilling: oldAccount.gradualBudgetFilling != account.gradualBudgetFilling ? account.gradualBudgetFilling : nil)
            )
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