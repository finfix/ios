//
//  ContentView.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @AppStorage("isLogin") var isLogin: Bool = false
    
    var body: some View {
        Group {
            if isLogin {
                MainView()
            } else {
                LoginView()
            }
        }
    }
}

struct MainView: View {
    var body: some View {
        TabView {
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
            
            BudgetsList()
                .tag(4)
                .tabItem {
                    Image(systemName: "ruler.fill")
                    Text("Бюджеты")
                }
            
            TransactionsView()
                .tag(3)
                .tabItem {
                    Image(systemName: "3.circle")
                    Text("Транзакции")
                }
            
            Profile()
                .tag(5)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Профиль")
                }
        }
    }
}

#Preview {
    ContentView()
}
