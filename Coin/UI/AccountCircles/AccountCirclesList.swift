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
    @State var path = NavigationPath()
    
    var groupedAccounts: [Account] {
        debugLog("Группируем счета")
        return groupAccounts(accounts, currencies: currencies)
    }

    init(path: NavigationPath, accountGroupID: UInt32) {
        self.path = path
        _accounts = Query(filter: #Predicate { $0.accountGroupID == accountGroupID && $0.visible } )
    }
    
    let rows = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let horizontalSpacing: CGFloat = 10
    
    var body: some View {
        NavigationStack(path: $path) {
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
                .navigationDestination(for: Account.self) { UpdateAccount(account: $0) }
                .navigationDestination(for: AccountType.self) { CreateAccount(accountType: $0) }
            }
        }
    }
}

struct AccountCircleList: View {
    
    @AppStorage("accountGroupID") var selectedAccountsGroupID: Int = 0
    @State var path = NavigationPath()
    
    var body: some View {
        AccountCirclesListSubView(path: path, accountGroupID: UInt32(selectedAccountsGroupID))
    }
}

#Preview {
    AccountCircleList()
}
