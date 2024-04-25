//
//  EditAccountViewModel.swift
//  Coin
//
//  Created by Илья on 26.03.2024.
//

import Foundation

enum mode {
    case create, update
}

@Observable
class EditAccountViewModel {
    private let service = Service.shared
    
    var currencies: [Currency] = []
    var icons: [Icon] = []
    var accountGroups: [AccountGroup] = []
    var accounts: [Account] = []
    
    var currentAccount = Account()
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
    }
    
    var permissions: AccountPermissions {
        GetPermissions(account: currentAccount)
    }
        
    func load() async throws {
        currencies = try await service.getCurrencies()
        accountGroups = try await service.getAccountGroups()
        icons = try await service.getIcons()
        var visible: Bool? = nil
        if !isHiddenView {
            visible = true
        }
        accounts = try await service.getAccounts(visible: visible, types: [currentAccount.type], isParent: true)
        if mode == .create {
            if let currency = currencies.first {
                currentAccount.currency = currency
            }
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
