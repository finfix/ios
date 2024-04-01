//
//  AppTabView.swift
//  Coin
//
//  Created by Илья on 15.11.2023.
//

import SwiftUI

struct AppTabView: View {
    
    @State var selectedAccountGroup = AccountGroup()
    
    var body: some View {
        TabView {
            AccountsHomeView(selectedAccountGroup: $selectedAccountGroup)
                .tag(1)
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.fill")
                    Text("Счета")
                }
            AccountCirclesView(selectedAccountGroup: $selectedAccountGroup)
                .tag(2)
                .tabItem {
                    Image(systemName: "2.circle")
                    Text("Счета 2")
                }
            TransactionsView(selectedAccountGroup: $selectedAccountGroup)
                .tag(3)
                .tabItem {
                    Image(systemName: "3.circle")
                    Text("Транзакции")
                }
            Profile(selectedAccountGroup: $selectedAccountGroup)
                .tag(5)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Профиль")
                }
        }
    }
}

#Preview {
    AppTabView()
}
