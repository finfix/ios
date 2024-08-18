//
//  AccountGroupService.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

import Foundation

extension Service {
    
    // MARK: Create
    func createAccountGroup(_ accountGroup: AccountGroup) async throws {
        var accountGroup = accountGroup
        
        try validateAccountGroup(accountGroup)
        
        let id = try await  repository.createAccountGroup(accountGroup)
        accountGroup.id = id
        
        taskManager.createTask(
            actionName: .createAccountGroup,
            localObjectID: id,
            reqModel: CreateAccountGroupReq(
                name: accountGroup.name,
                currency: accountGroup.currency.code,
                datetimeCreate: accountGroup.datetimeCreate
            )
        )
    }
    
    // MARK: Read
    func getAccountGroups() async throws -> [AccountGroup] {
        let currenciesMap = Currency.convertToMap(Currency.convertFromDBModel(try await  repository.getCurrencies()))
        return AccountGroup.convertFromDBModel(try await repository.getAccountGroups(), currenciesMap: currenciesMap)
    }
    
    // MARK: Update
    func updateAccountGroup(newAccountGroup: AccountGroup, oldAccountGroup: AccountGroup) async throws {
        
        try validateAccountGroup(newAccountGroup)
        
        try await  repository.updateAccountGroup(newAccountGroup)
        
        taskManager.createTask(
            actionName: .updateAccountGroup,
            localObjectID: newAccountGroup.id,
            reqModel: UpdateAccountGroupReq(
                id: newAccountGroup.id,
                name: newAccountGroup.name != oldAccountGroup.name ? newAccountGroup.name : nil,
                currency: newAccountGroup.currency != oldAccountGroup.currency ? newAccountGroup.currency.code : nil
            )
        )
    }
    
    // MARK: Delete
    func deleteAccountGroup(_ accountGroup: AccountGroup) async throws {
        try await repository.deleteAccountGroup(accountGroup)
        
        taskManager.createTask(
            actionName: .deleteAccountGroup,
            localObjectID: accountGroup.id,
            reqModel: DeleteAccountGroupReq(id: accountGroup.id)
        )
    }
    
    // MARK: Other
    private func validateAccountGroup(_ accountGroup: AccountGroup) throws {
        guard accountGroup.name != "" else { throw ErrorModel(humanText: "Группа счетов не может быть без имени") }
    }
}
