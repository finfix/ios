//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI

struct TransactionsTab: View {
    
    @State var path = NavigationPath()
    
    @Binding var selectedAccountGroup: AccountGroup
    
    var body: some View {
        NavigationStack(path: $path) {
            TransactionsView(path: $path, selectedAccountGroup: $selectedAccountGroup)
                .navigationDestination(for: TransactionsListRoute.self) { screen in
                    switch screen {
                    case .editTransaction(let transaction):
                        EditTransaction(transaction)
                    }
                }
        }
    }
}

#Preview {
    TransactionsTab(selectedAccountGroup: .constant(AccountGroup()))
        .environment(AlertManager(handle: {_ in }))
}
