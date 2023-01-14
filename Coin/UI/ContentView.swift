//
//  ContentView.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var auth: AppSettings
    
    var body: some View {
        if auth.isLogin {
            MainView()
        } else {
            LoginView()
        }
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
            
            ProfileView()
                .tag(4)
                .tabItem {
                    Image(systemName: "4.circle")
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

struct ProfileView: View {
    
    @EnvironmentObject var vm: AppSettings
    
    var body: some View {
        Button {
            vm.isLogin = false
        } label: {
            Text("Выйти")
        }

    }
}

/// Чтобы предварительный просмотр работал, не забудьте добавить environmentObject в предварительный просмотр ContentView, так как предварительный просмотр отличается от приложения:
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
    }
    
}
