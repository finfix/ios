//
//  CircleArray.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct CirclesArray: View {
    
    var accounts: [Account]
    
    var accountsType: AccountType
    
    var body: some View {
        ForEach(accounts.filter { ($0.type == accountsType) && $0.visible }) {
            AccountCircleItem(account: $0)
        }
        PlusNewAccount(accountType: accountsType)
    }
}

#Preview {
    CirclesArray(accounts: ModelData().accounts, accountsType: .regular)
}
