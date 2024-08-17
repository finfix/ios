//
//  EditAccountGroupViewModel.swift
//  Coin
//
//  Created by Илья on 23.05.2024.
//

import Foundation
import SwiftUI

@Observable
class EditAccountGroupViewModel {
    private let service = Service.shared
        
    var currentAccountGroup = AccountGroup()
    var oldAccountGroup = AccountGroup()
    var mode: mode
    var currencies: [Currency] = []
    
    init(
        currentAccountGroup: AccountGroup,
        oldAccountGroup: AccountGroup = AccountGroup(),
        mode: mode
    ) {
        self.currentAccountGroup = currentAccountGroup
        self.oldAccountGroup = oldAccountGroup
        self.mode = mode
    }
            
    func load() async throws {
        currencies = try await service.getCurrencies()
        
        if mode == .create {
            let users = try await service.getUsers()
            guard let user = users.first else { throw ErrorModel(humanText: "Не смогли получить пользователя") }
            currentAccountGroup.currency = user.defaultCurrency
        }
    }
    
    func createAccountGroup() async throws {
        try await service.createAccountGroup(currentAccountGroup)
    }
    
    func updateAccountGroup() async throws {
        try await service.updateAccountGroup(newAccountGroup: currentAccountGroup, oldAccountGroup: oldAccountGroup)
    }
    
    func deleteAccountGroup() async throws {
        try await service.deleteAccountGroup(currentAccountGroup)
    }
}
