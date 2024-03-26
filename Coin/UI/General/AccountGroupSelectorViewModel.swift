//
//  AccountGroupSelectorViewModel.swift
//  Coin
//
//  Created by Илья on 25.03.2024.
//

import Foundation

@Observable
class AccountGroupSelectorViewModel {
    private let service = Service.shared
    
    var accountGroups: [AccountGroup] = []
    
    func load() {
        do {
            accountGroups = try service.getAccountGroups()
        } catch {
            showErrorAlert("\(error)")
        }
    }
}
