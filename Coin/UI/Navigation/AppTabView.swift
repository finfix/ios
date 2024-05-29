//
//  AppTabView.swift
//  Coin
//
//  Created by Илья on 15.11.2023.
//

import SwiftUI

@Observable
final class AccountGroupSharedState {
    var selectedAccountGroup = AccountGroup()
}

@Observable
final class PathSharedState {
    var path = NavigationPath()
}

struct AppTabView: View {
    
    @State var selectedAccountGroup = AccountGroupSharedState()
    
    @State var selectionTab = 1
    
    var body: some View {
        TabView(selection: $selectionTab) {
            AccountsHomeView()
                .tag(1)
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.fill")
                    Text("Счета")
                }
            AccountCirclesView()
                .tag(2)
                .tabItem {
                    Image(systemName: "2.circle")
                    Text("Счета 2")
                }
            TransactionsTab()
                .tag(3)
                .tabItem {
                    Image(systemName: "3.circle")
                    Text("Транзакции")
                }
            Profile()
                .tag(4)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Профиль")
                }
        }
        .environment(selectedAccountGroup)
    }
}

#Preview {
    AppTabView()
}
