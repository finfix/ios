//
//  AccountGroupList.swift
//  Coin
//
//  Created by Илья on 22.05.2024.
//

import SwiftUI

enum AccountGroupListRoute: Hashable {
    case updateAccountGroup(AccountGroup)
    case createAccountGroup
}

struct AccountGroupList: View {
    
    let vm = AccountGroupListViewModel()
    @Environment(AlertManager.self) var alert
    @Environment(PathSharedState.self) var path
    
    var body: some View {
        List {
            ForEach(vm.accountGroups) { accountGroup in
                NavigationLink(value: AccountGroupListRoute.updateAccountGroup(accountGroup)) {
                    Text(accountGroup.name)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: AccountGroupListRoute.createAccountGroup) {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            do {
                try await vm.load()
            } catch {
                alert(error)
            }
        }
    }
}

#Preview {
    AccountGroupList()
}
