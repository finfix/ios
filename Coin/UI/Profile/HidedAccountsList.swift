//
//  HidedAccountsList.swift
//  Coin
//
//  Created by Илья on 27.10.2023.
//

import SwiftUI

struct HidedAccountsList: View {
    
    @Environment(ModelData.self) var modelData
    
    var filteredAccounts: [Account] {
        modelData.accounts.filter{ !$0.visible && !$0.isChild && $0.type == accountType && $0.accountGroupID == modelData.selectedAccountsGroupID }
    }
    
    @State var accountType: AccountType = .regular
    
    let columns = [
            GridItem(),
            GridItem(),
            GridItem(),
            GridItem()
        ]
        
    
    var body: some View {
        AccountsGroupSelector()
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(filteredAccounts) { account in
                    AccountCircleItem(account: account)
                }
            }
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
        .environment(ModelData())
}
