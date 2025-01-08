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
    
    let width: CGFloat = UIScreen.main.bounds.width
    let height: CGFloat = UIScreen.main.bounds.height
    
    var body: some View {
        List {
            ForEach(SearchViewListHeaders.allCases, id: \.rawValue) { header in
                Section(header: Text(header.name).font(.headline)) {
                    switch header {
                    case .earningAccounts:
                        ForEach(vm.earnings) { account in
                            Button(account.name) {
                                filters.account = account
                                searchText = ""
                            }
                        }
                    case .regularAccounts:
                        ForEach(vm.regulars) { account in
                            Button(account.name) {
                                filters.account = account
                                searchText = ""
                            }
                        }
                    case .expenseAccounts:
                        ForEach(vm.expenses) { account in
                            Button(account.name) {
                                filters.account = account
                                searchText = ""
                            }
                        }
                    case .accountGroups:
                        ForEach(vm.accountGroups) { accountGroup in
                            Button(accountGroup.name) {
                                searchText = ""
                            }
                        }
                    case .tags:
                        ForEach(vm.tags) { tag in
                            Button(tag.name) {
                                searchText = ""
                            }
                        }
                    case .noteTransaction:
                        Button("Искать транзакции по заметке по строке: \(searchText)") {
                            filters.searchText = searchText
                            searchText = ""
                        }
                    }
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
        filters: TransactionFilters(),
        chartType: .earningsAndExpenses
    )
    .environment(AlertManager(handle: {_ in }))
}
