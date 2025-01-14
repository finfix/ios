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
    
    @State private var shouldShowDateFrom = false
    @State private var shouldShowDateTo = false
    @Binding var searchText: String
    @Binding var filters: TransactionFilters
    @Binding var chartType: ChartType
    @Binding var showFilters: Bool
    
    let width: CGFloat = UIScreen.main.bounds.width
    let height: CGFloat = UIScreen.main.bounds.height
    
    var body: some View {
        List {
            Section(header: Text("Дата")) {
                ExpandableDatePicker(buttonName: "C", isCalendarShowing: $shouldShowDateFrom, date: $filters.dateFrom)
                ExpandableDatePicker(buttonName: "По", isCalendarShowing: $shouldShowDateTo, date: $filters.dateTo)
            }
            Section(header: Text("Типы транзакций")) {
                ForEach(TransactionType.allCases, id: \.rawValue) { transactionType in
                    Button(transactionType.name) {
//                        switch transactionType {
//                        case .expense:
//                            chartType = .expenses
//                        case .earnings:
//                            chartType = .earnings
//                        default: break
//                        }
                        filters.transactionTypes.append(transactionType)
                        searchText = ""
                        showFilters = false
                    }
                }
            }
            Section(header: Text("Заметки")) {
                Button("Искать транзакции по заметке по строке: \"\(searchText)\"") {
                    filters.searchText = searchText
                    searchText = ""
                    showFilters = false
                }
                .disabled(searchText.isEmpty)
            }
            Section(header: Text("Валюты")) {
                if !searchText.isEmpty {
                    ForEach(vm.currencies) { currency in
                        Button(currency.name) {
                            filters.currencies.append(currency)
                            searchText = ""
                            showFilters = false
                        }
                    }
                } else {
                    Text("Начните вводить для поиска валют")
                        .foregroundStyle(.secondary)
                }
            }
            Section(header: Text("Группы счетов")) {
                if !searchText.isEmpty {
                    ForEach(vm.accountGroups) { accountGroup in
                        Button(accountGroup.name) {
                            filters.accountGroups.append(accountGroup)
                            chartType = .earningsAndExpenses
                            searchText = ""
                            showFilters = false
                        }
                    }
                } else {
                    Text("Начните вводить для поиска групп счетов")
                        .foregroundStyle(.secondary)
                }
            }
            Section(header: Text("Доходы")) {
                if !searchText.isEmpty {
                    ForEach(vm.earnings) { account in
                        Button {
                            filters.accounts.append(account)
                            chartType = .earnings
                            searchText = ""
                            showFilters = false
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
                } else {
                    Text("Начните вводить для поиска доходных счетов")
                        .foregroundStyle(.secondary)
                }
            }
            Section(header: Text("Счета")) {
                if !searchText.isEmpty {
                    ForEach(vm.regulars) { account in
                        Button {
                            filters.accounts.append(account)
                            chartType = .earningsAndExpenses
                            searchText = ""
                            showFilters = false
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
                } else {
                    Text("Начните вводить для поиска балансовых счетов")
                        .foregroundStyle(.secondary)
                }
            }
            Section(header: Text("Расходы")) {
                if !searchText.isEmpty {
                    ForEach(vm.expenses) { account in
                        Button {
                            filters.accounts.append(account)
                            chartType = .expenses
                            searchText = ""
                            showFilters = false
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
                } else {
                    Text("Начните вводить для поиска расходных счетов")
                        .foregroundStyle(.secondary)
                }
            }
            Section(header: Text("Подкатегории")) {
                if !searchText.isEmpty {
                    ForEach(vm.tags) { tag in
                        Button {
                            filters.tags.append(tag)
                            chartType = .earningsAndExpenses
                            searchText = ""
                            showFilters = false
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
                } else {
                    Text("Начните вводить для поиска подкатегорий")
                        .foregroundStyle(.secondary)
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

struct ExpandableDatePicker: View {
    
    var buttonName: String
    @Binding var isCalendarShowing: Bool
    @Binding var date: Date?
    var showClearButton: Bool = true
    
    var body: some View {
        Group {
            Button {
                withAnimation {
                    isCalendarShowing.toggle()
                }
            } label: {
                Text(buttonName)
                Spacer()
                Group {
                    if let date {
                        Text(date, style: .date)
                    } else {
                        Text("Дата не выбрана")
                    }
                }
                .foregroundStyle(.secondary)
                if date != nil && showClearButton {
                    Button {
                        withAnimation {
                            date = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .buttonStyle(.plain)
            if isCalendarShowing {
                DatePicker(buttonName,
                           selection: Binding<Date>(get: {date ?? Date()}, set: {date = $0}),
                           displayedComponents: .date)
                .datePickerStyle(.graphical)
            }
        }
    }
}
