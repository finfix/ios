//
//  AccountHomeTab.swift
//  Coin
//
//  Created by Илья on 02.06.2024.
//

import SwiftUI

struct AccountHomeTab: View {
    
    @State var path = PathSharedState()
    @Environment(AccountGroupSharedState.self) var selectedAccountGroup
    
    var body: some View {
        NavigationStack(path: $path.path) {
            AccountsHomeView()
                .navigationDestination(for: CirclesCreateTransactionRoute.self ) { screen in
                    switch screen {
                    case .createTrasnaction(let transactionType):
                        EditTransaction(transactionType: transactionType, accountGroup: selectedAccountGroup.selectedAccountGroup)
                    }
                }
                .navigationDestination(for: EditTransactionRoute.self) { screen in
                    switch screen {
                    case .tagsList:
                        TagsList(accountGroup: selectedAccountGroup.selectedAccountGroup)
                    }
                }
                .navigationDestination(for: TagsListRoute.self) { screen in
                    switch screen {
                    case .createTag:
                        EditTag(selectedAccountGroup: selectedAccountGroup.selectedAccountGroup)
                    case .editTag(let tag):
                        EditTag(tag)
                    }
                }
        }
        .environment(path)
    }
}
