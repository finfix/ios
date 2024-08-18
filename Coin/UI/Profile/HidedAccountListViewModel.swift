//
//  HidedAccountListViewModel.swift
//  Coin
//
//  Created by Илья on 01.04.2024.
//

import Foundation
import Factory

@Observable
class HidedAccountViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var accounts: [Account] = []
    var type: AccountType = .regular
    
    func load() async throws {
        accounts = Account.groupAccounts(try await service.getAccounts(visible: false, types: [type]))
    }
}
