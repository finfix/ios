//
//  TransactionsList.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import SwiftUI

enum TransactionsListRoute: Hashable {
    case editTransaction(Transaction)
}

struct TransactionsList: View {
    
    @Environment (AlertManager.self) private var alert
    @State private var vm: TransactionsListViewModel
    @Binding var selectedAccountGroup: AccountGroup
    
    var searchText: String
    var dateFrom: Date?
    var dateTo: Date?
    var transactionType: TransactionType?
    var currency: Currency?
    var chartType: ChartType
    
    @Binding var path: NavigationPath
    
    let width: CGFloat = UIScreen.main.bounds.width
    let height: CGFloat = UIScreen.main.bounds.height
    
    init(
        path: Binding<NavigationPath>,
        selectedAccountGroup: Binding<AccountGroup>,
        account: Account? = nil,
        searchText: String = "",
        dateFrom: Date? = nil,
        dateTo: Date? = nil,
        transactionType: TransactionType? = nil,
        currency: Currency? = nil,
        chartType: ChartType
    ) {
        self._selectedAccountGroup = selectedAccountGroup
        self._path = path
        self.dateTo = dateTo
        self.dateFrom = dateFrom
        self.searchText = searchText
        self.transactionType = transactionType
        self.currency = currency
        self.chartType = chartType
        vm = TransactionsListViewModel(account: account)
    }
    
    var groupedTransactionByDate: [Date: [Transaction]] {
        let filteredTransactions = vm.transactions.filter { $0.accountFrom.accountGroup == selectedAccountGroup }
        return Dictionary(grouping: filteredTransactions, by: { $0.dateTransaction })
    }
    
    var body: some View {
        List {
            Section(footer:
                VStack {
                    ChartTab(chartType: chartType, selectedAccountGroup: selectedAccountGroup, account: vm.account, path: $path)
                    Button {
                        vm.heightCoef = vm.heightCoef != 1 ? 1 : 0.5
                    } label: {
                        Text("Больше информации")
                    }
                }
                .frame(width: width, height: height * vm.heightCoef)
            ){}
            ForEach(groupedTransactionByDate.keys.sorted(by: >), id: \.self) { date in
                Section(header: Text(date, style: .date).font(.headline)) {
                    ForEach(groupedTransactionByDate[date] ?? []) { transaction in
                        NavigationLink(value: TransactionsListRoute.editTransaction(transaction)) {
                            TransactionRow(transaction: transaction)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete {
                        for i in $0.makeIterator() {
                            Task {
                                do {
                                    try await vm.deleteTransaction(groupedTransactionByDate[date]![i])
                                } catch {
                                    alert(error)
                                }
                            }
                        }
                    }
                }
            }
            if !vm.transactionsCancelled {
                Text("Загрузка...")
                    .task {
                        do {
                            try await vm.load(refresh: false, dateFrom: dateFrom, dateTo: dateTo, searchText: searchText, transactionType: transactionType, currency: currency)
                        } catch {
                            alert(error)
                        }
                    }
            }
        }
        .task {
            if vm.transactions.count != 0 {
                do {
                    try await vm.load(refresh: true, dateFrom: dateFrom, dateTo: dateTo, searchText: searchText, transactionType: transactionType, currency: currency)
                } catch {
                    alert(error)
                }
            }
        }
        .onChange(of: dateFrom) { _, _ in
            Task {
                do {
                    try await vm.load(refresh: true, dateFrom: dateFrom, dateTo: dateTo, searchText: searchText, transactionType: transactionType, currency: currency)
                } catch {
                    alert(error)
                }
            }
        }
        .onChange(of: dateTo) { _, _ in
            Task {
                do {
                    try await vm.load(refresh: true, dateFrom: dateFrom, dateTo: dateTo, searchText: searchText, transactionType: transactionType, currency: currency)
                } catch {
                    alert(error)
                }
            }
        }
        .onChange(of: searchText) { _, _ in
            Task {
                do {
                    try await vm.load(refresh: true, dateFrom: dateFrom, dateTo: dateTo, searchText: searchText, transactionType: transactionType, currency: currency)
                } catch {
                    alert(error)
                }
            }
        }
        .onChange(of: transactionType) { _, _ in
            Task {
                do {
                    try await vm.load(refresh: true, dateFrom: dateFrom, dateTo: dateTo, searchText: searchText, transactionType: transactionType, currency: currency)
                } catch {
                    alert(error)
                }
            }
        }
        .onChange(of: currency) { _, _ in
            Task {
                do {
                    try await vm.load(refresh: true, dateFrom: dateFrom, dateTo: dateTo, searchText: searchText, transactionType: transactionType, currency: currency)
                } catch {
                    alert(error)
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Транзакции")
    }
}

#Preview {
    TransactionsList(path: .constant(NavigationPath()), selectedAccountGroup: .constant(AccountGroup(id: 4, currency: Currency(symbol: "₽"))), chartType: .earningsAndExpenses)
        .environment(AlertManager(handle: {_ in }))
}
