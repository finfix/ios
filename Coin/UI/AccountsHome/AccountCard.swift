//
//  AccountCard.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct AccountCard: View {
    
    var size: CGSize
    var account: Account
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Circle()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.gray)
                Text(account.name)
            }
            
            Text(currencyFormat(amount: account.remainder, currencyCode: account.currency))
        }
        .frame(width: size.width, height: 150)
        .background(Color("Gray"))
        .cornerRadius(17)
    }
}

#Preview {
    AccountCard(size: CGSize(width: 30, height: 30), account: ModelData().accounts[0])
}
