//
//  AccountCircleView.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI

struct AccountCircleList: View {
    
    @Environment(ModelData.self) var modelData
    
    var filteredAccounts: [Account] {
        modelData.accounts.filter { ( $0.accountGroupID == modelData.selectedAccountsGroupID ) && $0.visible && !$0.isChild }
    }
    
    let rows = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                Header()
                if modelData.accountGroups.count > 1 {
                    AccountsGroupSelector()
                }
                ScrollView(.horizontal) {
                    HStack {
                        CirclesArray(accounts: modelData.filteredAccounts, accountsType: .earnings)
                    }
                }.frame(maxHeight: 100)
                
                Divider()
                
                ScrollView(.horizontal) {
                    HStack {
                        CirclesArray(accounts: filteredAccounts, accountsType: .regular)
                    }
                }.frame(maxHeight: 100)
                
                Divider()
                
                ScrollView(.horizontal) {
                    LazyHGrid(rows: rows) {
                        CirclesArray(accounts: filteredAccounts, accountsType: .expense)
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
