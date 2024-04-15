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
    
    func load() throws -> AccountGroup {
        accountGroups = try service.getAccountGroups()
        return accountGroups.first ?? AccountGroup()
    }
}
