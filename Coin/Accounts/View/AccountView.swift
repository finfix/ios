//
//  OrderView.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI

struct AccountView: View {
    
    @EnvironmentObject var network: AccountAPI
    
    var body: some View {
        List(network.accounts, id: \.id) { account in
            if account.remainder != 0 {
                HStack {
                    Text(account.name)
                    
                    Spacer()
                    
                    Text(String(format: "%.2f", account.remainder))
                        .font(.footnote)
                }
                .padding()
            }
        }
        .onAppear {
            network.getAccounts()
        }
    }
}


struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}
