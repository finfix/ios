//
//  TransactionFilterViewModel.swift
//  Coin
//
//  Created by Илья on 01.05.2024.
//

import Foundation
import Factory

@Observable
class TransactionFilterViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var currencies: [Currency] = []
    var accountsMap: [UInt32: Account] = [:]
    var accountGroupsMap: [UInt32: AccountGroup] = [:]
    
    func load() async throws {
        currencies = try await service.getCurrencies()
        let accounts = try await service.getAccounts()
        accountsMap = Dictionary(uniqueKeysWithValues: accounts.map{ ($0.id, $0) })
        let accountGroups = try await service.getAccountGroups()
        accountGroupsMap = Dictionary(uniqueKeysWithValues: accountGroups.map{ ($0.id, $0) })
    }
}
