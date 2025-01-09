//
//  SearchView.swift
//  Coin
//
//  Created by Илья on 08.01.2025.
//

import SwiftUI

struct SearchView: View {
    
    @Environment(AlertManager.self) private var alert
    @State private var vm: SearchViewModel = SearchViewModel()
    
    @Binding var searchText: String
    @Binding var filters: TransactionFilters
    @Binding var chartType: ChartType
    
    let width: CGFloat = UIScreen.main.bounds.width
    let height: CGFloat = UIScreen.main.bounds.height
    
    var body: some View {
        List {
            Section(header: Text("Доходы")) {
                ForEach(vm.earnings) { account in
                    Button(account.name) {
                        filters.accounts.append(account)
                        chartType = .earnings
                        searchText = ""
                    }
                }
            }
            Section(header: Text("Счета")) {
                ForEach(vm.regulars) { account in
                    Button(account.name) {
                        filters.accounts.append(account)
                        chartType = .earningsAndExpenses
                        searchText = ""
                    }
                }
            }
            Section(header: Text("Расходы")) {
                ForEach(vm.expenses) { account in
                    Button(account.name) {
                        filters.accounts.append(account)
                        chartType = .expenses
                        searchText = ""
                    }
                }
            }
            Section(header: Text("Группы счетов")) {
                ForEach(vm.accountGroups) { accountGroup in
                    Button(accountGroup.name) {
                        filters.accountGroups.append(accountGroup)
                        chartType = .earningsAndExpenses
                        searchText = ""
                    }
                }
            }
            Section(header: Text("Подкатегории")) {
                ForEach(vm.tags) { tag in
                    Button(tag.name) {
                        filters.tags.append(tag)
                        chartType = .earningsAndExpenses
                        searchText = ""
                    }
                }
            }
            Section(header: Text("Заметки")) {
                Button("Искать транзакции по заметке по строке: \(searchText)") {
                    filters.searchText = searchText
                    searchText = ""
                }
            }
        }
        .task {
            do {
                try await vm.load(searchText: searchText)
            } catch {
                alert(error)
            }
        }
        .onChange(of: searchText) { _, _ in
            Task {
                do {
                    try await vm.load(searchText: searchText)
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
    TransactionsList(
        filters: TransactionFilters()
    )
    .environment(AlertManager(handle: {_ in }))
}
