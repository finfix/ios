//
//  HidedAccountsList.swift
//  Coin
//
//  Created by Илья on 27.10.2023.
//

import SwiftUI

struct HidedAccountsList: View {
    
    @Environment(ModelData.self) var modelData
    @AppStorage("accountGroupIndex") var selectedAccountsGroupIndex: Int = 0
    
    var filteredAccounts: [Account] {
        modelData.accounts.filter{ !$0.visible && $0.childrenAccounts.isEmpty && $0.type == accountType && $0.accountGroupID == modelData.accountGroups[selectedAccountsGroupIndex].id }
    }
    
    var groupedAccountsByCurrency: [String : [Account]] {
        Dictionary(grouping: filteredAccounts, by: { $0.currency })
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
                ForEach(groupedAccountsByCurrency.keys.sorted(by: >), id: \.self) { currency in
                    Section(header: Text(CurrencySymbols[currency]!)) {
                        ForEach(groupedAccountsByCurrency[currency] ?? []) { account in
                            AccountCircleItem(account: account)
                        }
                    }
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
