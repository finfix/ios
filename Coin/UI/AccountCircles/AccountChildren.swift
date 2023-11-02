//
//  AccountChildren.swift
//  Coin
//
//  Created by Илья on 19.10.2023.
//

import SwiftUI

struct AccountChildren: View {
    
    var parentAccount: Account
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(parentAccount.childrenAccounts) { childAccount in
                    AccountCircleItem(account: childAccount, alreadyOpened: true)
                }
                PlusNewAccount(accountType: parentAccount.type)
            }
        }
    }
}

#Preview {
    AccountChildren(parentAccount: Account())
}
