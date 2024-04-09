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
    
    init(
        currentAccount: Account,
        oldAccount: Account = Account(),
        mode: mode
    ) {
        self.currentAccount = currentAccount
        self.oldAccount = oldAccount
        self.mode = mode
    }
    
    var permissions: AccountPermissions {
        GetPermissions(account: currentAccount)
    }
        
    func load() {
        do {
            currencies = try service.getCurrencies()
            accountGroups = try service.getAccountGroups()
            accounts = try service.getAccounts(visible: true, types:[currentAccount.type], isParent: true)
            if mode == .create {
                currentAccount.currency = currencies.first ?? Currency()
            }
        } catch {
            showErrorAlert("\(error)")
        }
    }
    
    func createAccount() async throws {
        try await service.createAccount(currentAccount)
    }
    
    func updateAccount() async throws {
        try await service.updateAccount(newAccount: currentAccount, oldAccount: oldAccount)
    }
}
