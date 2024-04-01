//
//  HidedAccountListViewModel.swift
//  Coin
//
//  Created by Илья on 01.04.2024.
//

import Foundation

@Observable
class HidedAccountViewModel {
    private let service = Service.shared
    
    var accounts: [Account] = []
    var type: AccountType = .regular
    
    func load() {
        do {
            accounts = try service.getAccounts(visible: false, types: [type])
        } catch {
            showErrorAlert("\(error)")
        }
    }
}
