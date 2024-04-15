//
//  AccountGroupSelectorViewModel.swift
//  Coin
//
//  Created by Илья on 25.03.2024.
//

import Foundation
import SwiftUI

@Observable
class AccountGroupSelectorViewModel {
    private let service = Service.shared
    
    var accountGroups: [AccountGroup] = []
    
    func load() async throws -> AccountGroup {
        accountGroups = try await service.getAccountGroups()
        return accountGroups.first ?? AccountGroup()
    }
}
