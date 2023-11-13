//
//  ContentView.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @AppStorage("lastFetchedCurrencies") var lastFetchedCurrencies: Double = Date.now.timeIntervalSince1970
    @AppStorage("isLogin") var isLogin: Bool = false
    @Query var currencies: [Currency]
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        Group {
            if isLogin {
                MainView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            if hasExceededLimit() || currencies.isEmpty {
                getCurrencies()
            }
        }
    }
    
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
            let currencies = try await UserAPI().GetCurrencies()
            for currency in currencies { modelContext.insert(currency) }
            lastFetchedCurrencies = Date.now.timeIntervalSince1970
        }
    }
}

struct MainView: View {

    @Query var transactions: [Transaction]
    @Query var accounts: [Account]
    @Query var accountGroups: [AccountGroup]
    
    @Environment(\.modelContext) var modelContext
    
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
        .onAppear {
            if transactions.isEmpty {
                debugLog("Запросили транзакции с сервера")
                getTransactions()
            }
            if accounts.isEmpty {
                debugLog("Запросили счета с сервера")
                getAccounts()
            }
            if accountGroups.isEmpty {
                debugLog("Запросили группы счетов с сервера")
                getAccountGroups()
            }
        }
    }
}

extension MainView {
    
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
    
    func getAccountGroups() {
        Task {
            do {
                let accountGroups = try await AccountAPI().GetAccountGroups()
                for accountGroup in accountGroups { modelContext.insert(accountGroup) }
            } catch {
                debugLog(error)
            }
        }
    }
    
    func getAccounts() {
        Task {
            let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            let dateFrom = Calendar.current.date(from: DateComponents(year: today.year, month: today.month, day: 1))
            let dateTo = Calendar.current.date(from: DateComponents(year: today.year, month: today.month! + 1, day: 1))
            
            do {
                let accounts = try await AccountAPI().GetAccounts(req: GetAccountsReq(dateFrom: dateFrom, dateTo: dateTo))
                for account in accounts { modelContext.insert(account) }
            } catch {
                debugLog(error)
            }
        }
    }
}

#Preview {
    ContentView()
}
