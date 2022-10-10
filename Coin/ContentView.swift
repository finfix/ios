//
//  ContentView.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        TabView {
            TransactionView()
            .tabItem{
                Image(systemName: "1.circle")
                Text("Транзакции")
            }
            .tag(1)
            
            AccountView()
            .tag(2)
            .tabItem {
                Image(systemName: "2.circle")
                Text("Счета")
            }
        }
    }
}

/// Чтобы предварительный просмотр работал, не забудьте добавить environmentObject в предварительный просмотр ContentView, так как предварительный просмотр отличается от приложения:
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
