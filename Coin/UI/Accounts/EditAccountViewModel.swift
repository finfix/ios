//
//  EditAccountViewModel.swift
//  Coin
//
//  Created by Илья on 26.03.2024.
//

import Foundation
import Factory


enum mode {
    case create, update
}

@Observable
class EditAccountViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var currencies: [Currency] = []
    var icons: [Icon] = []
    var accountGroups: [AccountGroup] = []
    var accounts: [Account] = []
    
    var currentAccount = Account()
    var remainder: Double {
        didSet {
            currentAccount.remainder = Decimal(floatLiteral: remainder)
        }
    }
    var budgetAmount: Double {
        didSet {
            currentAccount.budgetAmount = Decimal(floatLiteral: budgetAmount)
        }
    }
    var budgetFixedSum: Double {
        didSet {
            currentAccount.budgetFixedSum = Decimal(floatLiteral: budgetFixedSum)
        }
    }
    var oldAccount = Account()
    
    var mode: mode
    var isHiddenView: Bool
    
    init(
        currentAccount: Account,
        oldAccount: Account = Account(),
        mode: mode,
        isHiddenView: Bool = false
    ) {
        self.currentAccount = currentAccount
        self.oldAccount = oldAccount
        self.mode = mode
        self.isHiddenView = isHiddenView
        self.budgetAmount = currentAccount.budgetAmount.doubleValue
        self.budgetFixedSum = currentAccount.budgetFixedSum.doubleValue
        self.remainder = currentAccount.remainder.doubleValue
    }
    
    var permissions: AccountPermissions {
        GetPermissions(account: currentAccount)
    }
        
    func load(accountGroup: AccountGroup) async throws {
        currencies = try await service.getCurrencies()
        accountGroups = try await service.getAccountGroups()
        icons = try await service.getIcons()
        var visible: Bool? = nil
        if !isHiddenView {
            visible = true
        }
        accounts = try await service.getAccounts(visible: visible, types: [currentAccount.type])
        if currentAccount.currency.code == "" {
            currentAccount.currency = currencies.first(where: { accountGroup.currency.code == $0.code }) ?? currencies.first ?? Currency()
        }
        if currentAccount.icon.id == 0 {
            if let icon = icons.first {
                currentAccount.icon = icon
            }
        }
    }
    
    func createAccount() async throws {
        try await service.createAccount(currentAccount)
    }
    
    func updateAccount() async throws {
        try await service.updateAccount(newAccount: currentAccount, oldAccount: oldAccount)
    }
    
    func deleteAccount() async throws {
        try await service.deleteAccount(currentAccount)
    }
}
