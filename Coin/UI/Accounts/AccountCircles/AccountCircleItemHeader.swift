//
//  AccountCircle.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct AccountCircleItemHeader: View {
    
    var account: Account
    
    var body: some View {
        Text(account.name)
            .lineLimit(1)
            .font(.caption)
    }
}
