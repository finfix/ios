//
//  ViewModel.swift
//  Coin
//
//  Created by Илья on 14.10.2022.
//

import SwiftUI

class AccountViewModel: ObservableObject {
    @Published var accounts = [Account]()
    
    @Published var visible = true
    @Published var accounting = true
    @Published var accountType = 1
    @Published var withoutZeroRemainder = true
    @Published var selectedAccountGroupID: Int = 0
    
    // Возможные типы счетов
    var types = ["earnings", "expense", "regular", "credit", "investment", "debt"]
    
    var accountsFiltered: [Account] {
        
        var subfiltered = accounts
        
        subfiltered = subfiltered.filter { $0.accountGroupID == selectedAccountGroupID }
        
        if visible {
            subfiltered = subfiltered.filter { $0.visible }
        }
        
        if accounting {
            subfiltered = subfiltered.filter { $0.accounting }
        }
        
        if accountType != 0 {
            subfiltered = subfiltered.filter { $0.typeSignatura == types[accountType] }
        }
        
        if withoutZeroRemainder {
            subfiltered = subfiltered.filter { $0.remainder != 0 }
        }
        
        return subfiltered.sorted { $0.remainder > $1.remainder }
    }
    
    func getAccount(_ settings: AppSettings) {
        AccountAPI().GetAccounts { model, error in
            if let err = error {
                settings.showErrorAlert(error: err)
            } else if let response = model {
                self.accounts = response
            }
        }
    }
}


