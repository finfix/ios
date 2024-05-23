//
//  AccountGroupListViewMode.swift
//  Coin
//
//  Created by Илья on 22.05.2024.
//

import Foundation

@Observable
class AccountGroupListViewModel {
    private let service = Service.shared
    
    var accountGroups: [AccountGroup] = []
        
    func load() async throws {
        accountGroups = try await service.getAccountGroups()
    }
}
