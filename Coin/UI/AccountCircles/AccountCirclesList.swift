//
//  AccountCircleView.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI
import SwiftData

struct AccountCircleList: View {
        
    @Query var currencies: [Currency]
    @Query var accounts: [Account]
    @Query var accountGroups: [AccountGroup]
    
    var groupedAccounts: [Account] {
        debugLog("Группируем счета")
        return groupAccounts(accounts, currencies: currencies)
    }
    
    let rows = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let horizontalSpacing: CGFloat = 10
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 5) {
                VStack(spacing: 0) {
                    Header()
                    if accountGroups.count > 1 {
                        AccountsGroupSelector()
                    }
                }
                ScrollView(.horizontal) {
                    HStack(spacing: horizontalSpacing) {
                        CirclesArray(accounts: groupedAccounts, accountsType: .earnings)
                    }
                }
                
                Divider()
                
                ScrollView(.horizontal) {
                    HStack(spacing: horizontalSpacing) {
                        CirclesArray(accounts: groupedAccounts, accountsType: .regular)
                    }
                }
                
                Divider()
                
                ScrollView(.horizontal) {
                    LazyHGrid(rows: rows, alignment: .top, spacing: horizontalSpacing) {
                        CirclesArray(accounts: groupedAccounts, accountsType: .expense)
                    }
                }
                .frame(maxHeight: .infinity)
                Spacer()
            }
        }
    }
}

#Preview {
    AccountCircleList()
}
