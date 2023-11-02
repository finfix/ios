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
    @Query var transactions: [Transaction]
    
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
        .onAppear {
            modelData.getAccounts()
            modelData.getAccountGroups()
        }
        .onAppear {
            if hasExceededLimit() || currencies.isEmpty {
                getCurrencies()
            }
            if transactions.isEmpty {
                print("Запросили транзакции с сервера")
                getTransactions()
            }
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
        Task {
            do {
                let currencies = try await UserAPI().GetCurrencies()
                for currency in currencies { modelContext.insert(currency) }
                lastFetchedCurrencies = Date.now.timeIntervalSince1970
            } catch {
                debugLog(error)
            }
        }
    }
    
    func getTransactions() {
        
        Task {
            do {
                let transactions = try await TransactionAPI().GetTransactions(req: GetTransactionReq())
                for transaction in transactions { modelContext.insert(transaction) }
            } catch {
                debugLog(error)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(ModelData())
}
