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
    @Binding var searchFocused: Bool
    
    let width: CGFloat = UIScreen.main.bounds.width
    let height: CGFloat = UIScreen.main.bounds.height
    
    var body: some View {
        List {
            Section(header: Text("Группы счетов")) {
                ForEach(vm.accountGroups) { accountGroup in
                    Button(accountGroup.name) {
                        filters.accountGroups.append(accountGroup)
                        chartType = .earningsAndExpenses
                        searchText = ""
                        searchFocused = false
                    }
                }
            }
            Section(header: Text("Доходы")) {
                ForEach(vm.earnings) { account in
                    Button {
                        filters.accounts.append(account)
                        if filters.accountGroups.isEmpty {
                            filters.accountGroups.append(account.accountGroup)
                        }
                        chartType = .earnings
                        searchText = ""
                        searchFocused = false
                    } label: {
                        HStack {
                            if filters.accountGroups.count != 1 {
                                Text(account.accountGroup.name)
                                Text("•")
                            }
                            if let parentAccount = account.parentAccount.account {
                                Text(parentAccount.name)
                                Text("•")
                            }
                            Text(account.name)
                        }
                    }
                }
            }
            Section(header: Text("Счета")) {
                ForEach(vm.regulars) { account in
                    Button {
                        filters.accounts.append(account)
                        if filters.accountGroups.isEmpty {
                            filters.accountGroups.append(account.accountGroup)
                        }
                        chartType = .earningsAndExpenses
                        searchText = ""
                        searchFocused = false
                    } label: {
                        HStack {
                            if filters.accountGroups.count != 1 {
                                Text(account.accountGroup.name)
                                Text("•")
                            }
                            if let parentAccount = account.parentAccount.account {
                                Text(parentAccount.name)
                                Text("•")
                            }
                            Text(account.name)
                        }
                    }
                }
            }
            Section(header: Text("Расходы")) {
                ForEach(vm.expenses) { account in
                    Button {
                        filters.accounts.append(account)
                        if filters.accountGroups.isEmpty {
                            filters.accountGroups.append(account.accountGroup)
                        }
                        chartType = .expenses
                        searchText = ""
                        searchFocused = false
                    } label: {
                        HStack {
                            if filters.accountGroups.count != 1 {
                                Text(account.accountGroup.name)
                                Text("•")
                            }
                            if let parentAccount = account.parentAccount.account {
                                Text(parentAccount.name)
                                Text("•")
                            }
                            Text(account.name)
                        }
                    }
                }
            }
            Section(header: Text("Подкатегории")) {
                ForEach(vm.tags) { tag in
                    Button {
                        filters.tags.append(tag)
                        if filters.accountGroups.isEmpty {
                            filters.accountGroups.append(tag.accountGroup)
                        }
                        chartType = .earningsAndExpenses
                        searchText = ""
                        searchFocused = false
                    } label: {
                        HStack {
                            if filters.accountGroups.count != 1 {
                                Text(tag.accountGroup.name)
                                Text("•")
                            }
                            Text(tag.name)
                        }
                    }
                }
            }
            Section(header: Text("Заметки")) {
                Button("Искать транзакции по заметке по строке: \(searchText)") {
                    filters.searchText = searchText
                    searchText = ""
                    searchFocused = false
                }
            }
        }
        .task {
            do {
                try await vm.load(filters: filters, searchText: searchText)
            } catch {
                alert(error)
            }
        }
        .onChange(of: searchText) { _, _ in
            Task {
                do {
                    try await vm.load(filters: filters, searchText: searchText)
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
