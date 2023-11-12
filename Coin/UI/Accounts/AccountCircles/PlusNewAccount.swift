//
//  PlusNewAccount.swift
//  Coin
//
//  Created by Илья on 22.10.2023.
//

import SwiftUI

struct PlusNewAccount: View {
    
    var accountType: AccountType
    
    var body: some View {
        NavigationLink(value: accountType) {
            VStack {
                ZStack {
                    Circle()
                        .stroke(.gray, lineWidth: 2)
                        .foregroundColor(.clear)
                        .frame(width: 30)
                    Image(systemName: "plus")
                        .foregroundColor(.gray)
                }
                .foregroundColor(.primary)
            }
            .frame(width: 80, height: 100)
        }
    }
}

#Preview {
    PlusNewAccount(accountType: .regular)
}
