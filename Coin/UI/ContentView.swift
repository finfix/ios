//
//  ContentView.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI

struct ContentView: View {
    
    @AppStorage("isLogin") var isLogin: Bool = false
    
    var body: some View {
        if isLogin {
            MainView()
        } else {
            LoginView()
        }
    }
}

struct MainView: View {
    
    @Environment(ModelData.self) var modelData
    
    var body: some View {
        TabView {
            AccountsHome()
                .tag(1)
                .tabItem {
                    Image(systemName: "1.circle")
                    Text("Счета")
                }
            
            AccountCircleList()
                .tag(2)
                .tabItem {
                    Image(systemName: "2.circle")
                    Text("Счета 2")
                }
            
            TransactionsList()
                .tag(3)
                .tabItem {
                    Image(systemName: "3.circle")
                    Text("Транзакции")
                }
            
            BudgetsList()
                .tag(4)
                .tabItem {
                    Image(systemName: "4.circle")
                    Text("Бюджеты")
                }
            
            Profile()
                .tag(5)
                .tabItem {
                    Image(systemName: "5.circle")
                    Text("Профиль")
                }
        }
        .onAppear(perform: modelData.sync)
    }
}

#Preview {
    ContentView()
        .environment(ModelData())
}
