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
        if isLogin {
            MainView()
        } else {
            LoginView()
        }
    }
}

struct MainView: View {
    
    @Environment(ModelData.self) var modelData
    @Query var currencies: [Currency]
    
    @Environment(\.modelContext) var modelContext
    
    @AppStorage("lastFetchedCurrencies") var lastFetchedCurrencies: Double = Date.now.timeIntervalSince1970
    
    var body: some View {
        TabView {
            AccountsHome()
                .tag(1)
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.fill")
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
                    Image(systemName: "ruler.fill")
                    Text("Бюджеты")
                }
            
            Profile()
                .tag(5)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Профиль")
                }
        }
        .onAppear {
            modelData.getAccounts()
            modelData.getAccountGroups()
            modelData.getTransactions()
        }
        .onAppear {
            if hasExceededLimit() || currencies.isEmpty {
                getCurrencies()
            }
            modelData.currencies = Dictionary(uniqueKeysWithValues: currencies.map{ ($0.isoCode, $0) })
        }
    }
}

extension MainView {
    
    func hasExceededLimit() -> Bool {
        let timeLimit = 3600 // 1 hour
        let currentTime = Date.now
        let lastFetchedCurrenciesTime = Date(timeIntervalSince1970: lastFetchedCurrencies)
        
        guard let differenceInMins = Calendar.current.dateComponents([.second],
                                                                     from: lastFetchedCurrenciesTime,
                                                                     to: currentTime).second else {
            return false
        }
        return differenceInMins >= timeLimit
    }
    
    func getCurrencies() {
        
        UserAPI().GetCurrencies() { model, error in
            if let err = error {
                showErrorAlert(error: err)
            } else if let currencies = model {
                for currency in currencies { modelContext.insert(currency) }
            }
        }
        
        lastFetchedCurrencies = Date.now.timeIntervalSince1970
    }
}

#Preview {
    ContentView()
        .environment(ModelData())
}
