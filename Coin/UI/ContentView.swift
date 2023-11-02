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
    
    @Query var currencies: [Currency]
    @Query var transactions: [Transaction]
    @Query var accounts: [Account]
    @Query var accountGroups: [AccountGroup]
    
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
            if hasExceededLimit() || currencies.isEmpty {
                getCurrencies()
            }
            if transactions.isEmpty {
                print("Запросили транзакции с сервера")
                getTransactions()
            }
            if accounts.isEmpty {
                print("Запросили счета с сервера")
                getAccounts()
            }
            if accountGroups.isEmpty {
                print("Запросили группы счетов с сервера")
                getAccountGroups()
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
    
    func getAccountGroups() {
        AccountAPI().GetAccountGroups() { accountGroups, error in
            if let err = error {
                showErrorAlert(error: err)
            } else if let accountGroups {
                for accountGroup in accountGroups { modelContext.insert(accountGroup) }
            }
        }
    }
    
    func getAccounts() {
            
            let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            let dateFrom = Calendar.current.date(from: DateComponents(year: today.year, month: today.month, day: 1))
            let dateTo = Calendar.current.date(from: DateComponents(year: today.year, month: today.month! + 1, day: 1))
            
            AccountAPI().GetAccounts(req: GetAccountsRequest(dateFrom: dateFrom, dateTo: dateTo)) { accounts, error in
                if let err = error {
                    showErrorAlert(error: err)
                } else if let accounts {
                    for account in accounts { modelContext.insert(account) }
                }
            }
        }
}

#Preview {
    ContentView()
}
