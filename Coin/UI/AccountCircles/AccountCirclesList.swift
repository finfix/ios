//
//  AccountCircleView.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI
import SwiftData

struct AccountCirclesListSubView: View {
    
    @Query var accounts: [Account]
    @State var path = NavigationPath()

    init(path: NavigationPath, accountGroupID: UInt32) {
        debugLog("\nИнициализировали AccountCirclesListSubView")
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
        let groupedAccounts = groupAccounts(accounts)
        
        NavigationStack(path: $path) {
            VStack(spacing: 5) {
                VStack(spacing: 0) {
                    Header()
                    AccountsGroupSelector()
                }
                Group {
                    ScrollView(.horizontal) {
                        HStack(spacing: horizontalSpacing) {
                            ForEach(groupedAccounts.filter { $0.type == .earnings }) { account in
                                AccountCircleItem(account, path: $path)
                            }
                            PlusNewAccount(accountType: .earnings)
                        }
                    }
                    
                    Divider()
                    
                    ScrollView(.horizontal) {
                        HStack(spacing: horizontalSpacing) {
                            ForEach(groupedAccounts.filter { $0.type == .regular }) { account in
                                AccountCircleItem(account, path: $path)
                            }
                            PlusNewAccount(accountType: .regular)
                        }
                    }
                    
                    Divider()
                    
                    ScrollView(.horizontal) {
                        LazyHGrid(rows: rows, alignment: .top, spacing: horizontalSpacing) {
                            ForEach(groupedAccounts.filter { $0.type == .expense }) { account in
                                AccountCircleItem(account, path: $path)
                            }
                            PlusNewAccount(accountType: .expense)
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                .navigationDestination(for: Account.self) { UpdateAccount(account: $0) }
                .navigationDestination(for: AccountType.self) { CreateAccount(accountType: $0) }
            }
            Spacer()
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
