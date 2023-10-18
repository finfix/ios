//
//  AccountCircle.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct AccountCircleItem: View {
    
    var account: Account
    
    var body: some View {
        VStack {
            Text(account.name)
                .lineLimit(1)
                .font(.footnote)
            
            Circle()
                .frame(width: 30)
                .foregroundColor(account.budget == 0 ? .gray : account.budget >= account.remainder ? .green : .red)

            Text("\(String(format: "%.2f", account.remainder)) \(account.currencySymbol)")
                .lineLimit(1)
                .font(.footnote)
            
            if account.budget != 0 {
                Text("\(String(format: "%.0f", account.budget)) \(account.currencySymbol)")
                    .lineLimit(1)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 70)
    }
}

#Preview {
    AccountCircleItem(account: ModelData().accounts[0])
}
