//
//  AccountCircle.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct AccountCircleItemFooter: View {
    
    var formatter: CurrencyFormatter
    var account: Account
    
    init(account: Account) {
        self.formatter = CurrencyFormatter(currency: account.currency)
        self.account = account
        if account.type == .balancing && account.showingRemainder < 0 && account.isParent {
            self.account.showingRemainder *= -1
        }
    }
    
    var body: some View {
        Text(formatter.string(number: account.showingRemainder))
            .lineLimit(1)
            .font(.caption)
        
        Text(account.showingBudgetAmount != 0 ? formatter.string(number: account.showingBudgetAmount) : " ")
            .lineLimit(1)
            .foregroundColor(.secondary)
            .font(.caption)
    }
}
