//
//  HidedAccountsList.swift
//  Coin
//
//  Created by Илья on 27.10.2023.
//

import SwiftUI
import SwiftData

struct HidedAccountsList: View {
    
    @AppStorage("accountGroupID") var selectedAccountsGroupID: Int = 0
    @Query var accounts: [Account]
    @Query var accountGroups: [AccountGroup]
    
    @State var accountType: AccountType = .regular
    
    @State var path = NavigationPath()
    
    let columns = [
        GridItem(),
        GridItem(),
        GridItem(),
        GridItem()
    ]
    
    init() {
        _accounts = Query(filter: #Predicate {
            !$0.visible /* &&
            $0.type == accountType &&
            $0.accountGroupID == accountGroups[selectedAccountsGroupIndex].id */ })
    }
    
    
    var body: some View {
        NavigationStack(path: $path) {
            AccountsGroupSelector()
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(accounts) { account in
                        AccountCircleItem(account, path: $path)
                    }
                }
            }
            .navigationDestination(for: Account.self) { CreateAccount($0) }
        }
        .toolbar {
            Picker("Тип счета", selection: $accountType) {
                ForEach(AccountType.allCases, id: \.self) { value in
                    Text(value.rawValue)
                        .tag(value)
                }
            }
        }
    }
}

#Preview {
    HidedAccountsList()
}
