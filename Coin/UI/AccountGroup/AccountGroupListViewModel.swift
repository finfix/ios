//
//  AccountGroupListViewMode.swift
//  Coin
//
//  Created by Илья on 22.05.2024.
//

import Foundation
import Factory

@Observable
class AccountGroupListViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var accountGroups: [AccountGroup] = []
        
    func load() async throws {
        accountGroups = try await service.getAccountGroups()
    }
}
