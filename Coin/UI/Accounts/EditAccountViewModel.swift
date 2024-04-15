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
        
    func load() throws {
        currencies = try service.getCurrencies()
        accountGroups = try service.getAccountGroups()
        var visible: Bool? = nil
        if !isHiddenView {
            visible = true
        }
        accounts = try service.getAccounts(visible: visible, types: [currentAccount.type], isParent: true)
        if mode == .create {
            currentAccount.currency = currencies.first ?? Currency()
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
