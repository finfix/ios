//
//  DeveloperToolsTab.swift
//  Coin
//
//  Created by Илья on 02.06.2024.
//

import SwiftUI

struct DeveloperToolsTab: View {
    
    @State var path = PathSharedState()
    
    var body: some View {
        NavigationStack(path: $path.path) {
            DeveloperTools()
                .navigationDestination(for: DeveloperToolsRoute.self) { screen in
                    switch screen {
                    case .tasksList: TasksList()
                    }
                }
                .navigationDestination(for: TasksListRoute.self) { screen in
                    switch screen {
                    case .taskDetails(let task): TaskDetails(task: task)
                    case .taskGraph: TaskGraph()
                    }
                }
                .navigationDestination(for: DeveloperObjectRoute.self) { screen in
                    switch screen {
                    case .account(let account): EditAccount(account, selectedAccountGroup: account.accountGroup)
                    case .transaction(let transaction): EditTransaction(transaction)
                    case .tag(let tag): EditTag(tag)
                    case .accountGroup(let accountGroup): EditAccountGroup(accountGroup)
                    }
                }

        }
        .environment(path)
    }
}

#Preview {
    DeveloperToolsTab()
}
