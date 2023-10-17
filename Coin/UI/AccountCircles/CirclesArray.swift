//
//  CircleArray.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct CirclesArray: View {
    
    var accounts: [Account]
    
    var body: some View {
        ForEach(accounts, id: \.id) { account in
            AccountCircleItem(account: account)
        }
        .frame(width: 90)
    }
}

#Preview {
    CirclesArray(accounts: ModelData().accounts)
}
