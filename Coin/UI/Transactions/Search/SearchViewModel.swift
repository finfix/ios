//
//  SearchViewModel.swift
//  Coin
//
//  Created by Илья on 08.01.2025.
//

import Foundation
import Factory

@Observable
class SearchViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var accountGroups: [AccountGroup] = []
    
    var earnings: [Account] = []
    var regulars: [Account] = []
    var expenses: [Account] = []
    
    var tags: [Tag] = []
    
    var currencies: [Currency] = []
    
    @MainActor
    func load(filters: TransactionFilters, searchText: String = "") async throws {
        
        self.accountGroups = []
        self.earnings = []
        self.regulars = []
        self.expenses = []
        self.tags = []
        self.currencies = []
        
        tags = try await service.getTags(name: searchText)
        var accounts = try await service.getAccounts(accountGroups: filters.accountGroups.isEmpty ? nil : filters.accountGroups, name: searchText)
        accounts = Account.groupAccounts(accounts)
        for account in accounts {
            switch account.type {
            case .earnings:
                earnings.append(account)
            case .debt, .balancing, .regular:
                regulars.append(account)
            case .expense:
                expenses.append(account)
            }
        }
        accountGroups = try await service.getAccountGroups(name: searchText)
        currencies = try await service.getCurrencies(searchText: searchText)
    }
}
