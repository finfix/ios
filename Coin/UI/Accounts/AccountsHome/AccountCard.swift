//
//  AccountCard.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct AccountCard: View {
    
    var account: Account
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Circle()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.gray)
                Text(account.name)
            }
            Text(CurrencyFormatter().string(number: account.remainder, currency: account.currency))
        }
        .frame(width: 300, height: 150)
        .background(Color("Gray"))
        .cornerRadius(17)
    }
}

#Preview {
    AccountCard(account: Account())
        .environment(AlertManager(handle: {_ in }))
}
