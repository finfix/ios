//
//  ContentView.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(AppSettings.self) var appSettings
    
    var body: some View {
        if appSettings.isLogin {
            MainView()
        } else {
            LoginView()
        }
    }
}

struct MainView: View {
    
    @Environment(AppSettings.self) var appSettings
    @Environment(ModelData.self) var modelData
    
    var body: some View {
        TabView {
            Accounts()
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
            
            // GraphView(rangeTime: 0..<(myLine.points.count - 1),
            //           line: myLine, lineWidth: 2)
            //     .border(.black)
            //     .tag(5)
            //     .tabItem {
            //         Image(systemName: "5.circle")
            //         Text("График")
            //     }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppSettings())
        .environment(ModelData())
}
