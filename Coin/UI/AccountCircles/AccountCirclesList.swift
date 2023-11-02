//
//  AccountCircleView.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI
import SwiftData

struct AccountCircleList: View {
    
    @Environment(ModelData.self) var modelData
    
    @Query var currencies: [Currency]
    @AppStorage("accountGroupIndex") var selectedAccountsGroupIndex: Int = 0
    
    var accounts: [Account] {
        debugLog("Группируем счета")
        let tmp = modelData.accounts.filter { ( $0.accountGroupID == modelData.accountGroups[selectedAccountsGroupIndex].id ) && $0.visible }
        return groupAccounts(accounts: tmp, currencies: currencies)
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
                    if modelData.accountGroups.count > 1 {
                        AccountsGroupSelector()
                    }
                }
                ScrollView(.horizontal) {
                    HStack(spacing: horizontalSpacing) {
                        CirclesArray(accounts: accounts, accountsType: .earnings)
                    }
                }
                
                Divider()
                
                ScrollView(.horizontal) {
                    HStack(spacing: horizontalSpacing) {
                        CirclesArray(accounts: accounts, accountsType: .regular)
                    }
                }
                
                Divider()
                
                ScrollView(.horizontal) {
                    LazyHGrid(rows: rows, alignment: .top, spacing: horizontalSpacing) {
                        CirclesArray(accounts: accounts, accountsType: .expense)
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
        .environment(ModelData())
}
