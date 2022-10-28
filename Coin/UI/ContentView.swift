//
//  ContentView.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI
import RealmSwift

struct ContentView: View {
    
    @EnvironmentObject var auth: AppSettings
    
    var body: some View {
        Group {
            if auth.isLogin {
                MainView()
            } else {
                LoginView()
            }
        }
        .onAppear { print("База данных реалм лежит тут: " + (Realm.Configuration.defaultConfiguration.fileURL!.path)) }
    }
}

struct MainView: View {
    
    @EnvironmentObject var vm: AppSettings
    
    var body: some View {
        TabView {
            AccountView()
                .tag(1)
                .tabItem {
                    Image(systemName: "1.circle")
                    Text("Счета")
                }
            
            AccountCircleView()
                .tag(2)
                .tabItem {
                    Image(systemName: "2.circle")
                    Text("Счета 2")
                }
            
            TransactionView()
                .tag(3)
                .tabItem {
                    Image(systemName: "3.circle")
                    Text("Транзакции")
                }
            
            LogoutView()
                .tag(4)
                .tabItem {
                    Image(systemName: "4.circle")
                    Text("Выход")
                }
                .onAppear {
                    vm.isLogin = false
                }
        }
    }
}

struct LogoutView: View {
    var body: some View {
        Text("HELLO")
    }
}

/// Чтобы предварительный просмотр работал, не забудьте добавить environmentObject в предварительный просмотр ContentView, так как предварительный просмотр отличается от приложения:
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
    }
    
}
