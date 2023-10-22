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
                        CirclesArray(accounts: modelData.filteredAccounts, accountsType: .earnings)
                    }
                }
                
                Divider()
                
                ScrollView(.horizontal) {
                    HStack(spacing: horizontalSpacing) {
                        CirclesArray(accounts: filteredAccounts, accountsType: .regular)
                    }
                }
                
                Divider()
                
                ScrollView(.horizontal) {
                    LazyHGrid(rows: rows, alignment: .top, spacing: horizontalSpacing) {
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
        .environment(ModelData())
}
