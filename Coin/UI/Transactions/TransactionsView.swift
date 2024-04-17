//
//  TransactionsView.swift
//  Coin
//
//  Created by Илья on 17.04.2024.
//

import SwiftUI

struct TransactionsView: View {
    
    @Binding var path: NavigationPath
    @State var isFilterOpen = false
    @State private var searchText = ""
    @State var dateFrom: Date?
    @State var dateTo: Date?
    @Binding var selectedAccountGroup: AccountGroup
    var account: Account? = nil
    
    
    var body: some View {
        TransactionsList(path: $path, selectedAccountGroup: $selectedAccountGroup, account: account, searchText: searchText, dateFrom: dateFrom, dateTo: dateTo)
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    // Фильтры
                    Button { isFilterOpen.toggle() } label: { Label("Фильтры", systemImage: "line.3.horizontal.decrease.circle") }
                }
                if account == nil {
                    ToolbarItem(placement: .topBarLeading) {
                        AccountGroupSelector(selectedAccountGroup: $selectedAccountGroup)
                    }
                }
            }
            .sheet(isPresented: $isFilterOpen) { TransactionFilterView(dateFrom: $dateFrom, dateTo: $dateTo) }

    }
}

#Preview {
    TransactionsView(path: .constant(NavigationPath()), selectedAccountGroup: .constant(AccountGroup()))
}
