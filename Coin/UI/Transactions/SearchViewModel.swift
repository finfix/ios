//
//  SearchViewModel.swift
//  Coin
//
//  Created by Илья on 08.01.2025.
//

import Foundation
import Factory

enum SearchViewListHeaders: String, Hashable, CaseIterable {
    case earningAccounts
    case regularAccounts
    case expenseAccounts
    case tags
    case accountGroups
    case noteTransaction
    
    var name: String {
        switch self {
        case .accountGroups:
            return "Группы счетов"
        case .earningAccounts:
            return "Доходы"
        case .regularAccounts:
            return "Счета"
        case .expenseAccounts:
            return "Расходы"
        case .tags:
            return "Подкатегории"
        case .noteTransaction:
            return "Замеки"
        }
    }
}

@Observable
class SearchViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var accountGroups: [AccountGroup] = []
    
    var earnings: [Account] = []
    var regulars: [Account] = []
    var expenses: [Account] = []
    
    var tags: [Tag] = []
    
    func load(
        searchText: String = ""
    ) async throws {
        
        guard searchText != "" else {
            return
        }
        
        self.accountGroups = []
        self.earnings = []
        self.regulars = []
        self.expenses = []
        self.tags = []
        
        tags = try await service.getTags(name: searchText)
        let accounts = try await service.getAccounts(name: searchText)
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
        print("Теги: \(tags.count)")
        print("Счета: \(accounts.count)")
        print("Группы счетов: \(accountGroups.count)")
    }
}
