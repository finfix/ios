//
//  AccountCirclesViewModel.swift
//  Coin
//
//  Created by Илья on 25.03.2024.
//

import Foundation

@Observable
class AccountCirclesViewModel {
    private let service = Service.shared
    
    var accounts: [Account] = []
        
    func load() {
        do {
            accounts = Account.groupAccounts(try service.getAccounts(visible: true))
        } catch {
            showErrorAlert("\(error)")
        }
    }
}
