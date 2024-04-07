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
        self.permissions = GetPermissions(account: currentAccount)
    }
    
    var permissions: AccountPermissions
        
    func load() {
        do {
            currencies = try service.getCurrencies()
            accountGroups = try service.getAccountGroups()
            if mode == .create {
                currentAccount.currency = currencies.first ?? Currency()
            }
        } catch {
            showErrorAlert("\(error)")
        }
    }
    
    func createAccount() async {
        do {           
            try await service.createAccount(currentAccount)
        } catch {
            showErrorAlert("\(error)")
        }
    }
    
    func updateAccount() async {
        do {
            try await service.updateAccount(newAccount: currentAccount, oldAccount: oldAccount)
        } catch {
            showErrorAlert("\(error)")
        }
    }
}
