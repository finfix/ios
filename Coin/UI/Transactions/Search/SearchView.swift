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
    @Binding var areFiltersLocked: Bool
    
    let width: CGFloat = UIScreen.main.bounds.width
    let height: CGFloat = UIScreen.main.bounds.height

    var body: some View {
        List {
            Section {
                TextField("Поиск", text: $searchText)
            }

            // Фильтр по счетам — самый частый, поэтому сразу под поиском, наверху.
            CollapsibleFilterSection(
                title: "Доходы",
                count: searchText.isEmpty ? nil : vm.earnings.filter { !filters.accounts.contains($0) && !filters.excludedAccounts.contains($0) }.count
            ) {
                if !searchText.isEmpty {
                    ForEach(vm.earnings.filter { !filters.accounts.contains($0) && !filters.excludedAccounts.contains($0) }) { account in
                        FilterableAccountRow(account: account, showAccountGroup: filters.accountGroups.count != 1) {
                            filters.accounts.append(account)
                            chartType = .earnings
                        } onExclude: {
                            filters.excludedAccounts.append(account)
                        }
                    }
                } else {
                    Text("Начните вводить для поиска доходных счетов")
                        .foregroundStyle(.secondary)
                }
            }
            CollapsibleFilterSection(
                title: "Счета",
                count: searchText.isEmpty ? nil : vm.regulars.filter { !filters.accounts.contains($0) && !filters.excludedAccounts.contains($0) }.count
            ) {
                if !searchText.isEmpty {
                    ForEach(vm.regulars.filter { !filters.accounts.contains($0) && !filters.excludedAccounts.contains($0) }) { account in
                        FilterableAccountRow(account: account, showAccountGroup: filters.accountGroups.count != 1) {
                            filters.accounts.append(account)
                            chartType = .earningsAndExpenses
                        } onExclude: {
                            filters.excludedAccounts.append(account)
                        }
                    }
                } else {
                    Text("Начните вводить для поиска балансовых счетов")
                        .foregroundStyle(.secondary)
                }
            }
            CollapsibleFilterSection(
                title: "Расходы",
                count: searchText.isEmpty ? nil : vm.expenses.filter { !filters.accounts.contains($0) && !filters.excludedAccounts.contains($0) }.count
            ) {
                if !searchText.isEmpty {
                    ForEach(vm.expenses.filter { !filters.accounts.contains($0) && !filters.excludedAccounts.contains($0) }) { account in
                        FilterableAccountRow(account: account, showAccountGroup: filters.accountGroups.count != 1) {
                            filters.accounts.append(account)
                            chartType = .expenses
                        } onExclude: {
                            filters.excludedAccounts.append(account)
                        }
                    }
                } else {
                    Text("Начните вводить для поиска расходных счетов")
                        .foregroundStyle(.secondary)
                }
            }

            // Группы счетов — доступны всегда, без завязки на строку поиска (их обычно
            // немного, в отличие от отдельных счетов, так что поиск тут не нужен).
            CollapsibleFilterSection(
                title: "Группы счетов",
                count: vm.accountGroups.filter { !filters.accountGroups.contains($0) }.count
            ) {
                ForEach(vm.accountGroups.filter { !filters.accountGroups.contains($0) }) { accountGroup in
                    Button(accountGroup.name) {
                        filters.accountGroups.append(accountGroup)
                        chartType = .earningsAndExpenses
                    }
                }
            }

            CollapsibleFilterSection(title: "Управление фильтрами") {
                Button {
                    areFiltersLocked.toggle()
                } label: {
                    HStack {
                        Text(areFiltersLocked ? "Разблокировать фильтры" : "Зафиксировать фильтры")
                        Spacer()
                        Image(systemName: areFiltersLocked ? "lock.fill" : "lock.open.fill")
                            .foregroundStyle(areFiltersLocked ? .blue : .secondary)
                    }
                }

                Button {
                    // Сбрасываем все фильтры, кроме текущей группы счетов
                    let currentAccountGroups = filters.accountGroups
                    filters = TransactionFilters(accountGroups: currentAccountGroups)
                } label: {
                    HStack {
                        Text("Сбросить фильтры")
                        Spacer()
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            CollapsibleFilterSection(title: "Дата") {
                ExpandableDatePicker(buttonName: "C", isCalendarShowing: $shouldShowDateFrom, date: $filters.dateFrom)
                // Конец диапазона нормализуем на конец выбранного дня, иначе выбранная
                // дата фактически исключается из диапазона (фильтр сравнивает по времени,
                // а из пикера приходит полночь этого дня).
                ExpandableDatePicker(buttonName: "По", isCalendarShowing: $shouldShowDateTo, date: $filters.dateTo, normalizeToEndOfDay: true)
            }
            CollapsibleFilterSection(
                title: "Типы транзакций",
                count: TransactionType.allCases.filter { !filters.transactionTypes.contains($0) }.count
            ) {
                ForEach(TransactionType.allCases.filter { !filters.transactionTypes.contains($0) }, id: \.rawValue) { transactionType in
                    Button(transactionType.name) {
                        filters.transactionTypes.append(transactionType)
                    }
                }
            }
            CollapsibleFilterSection(title: "Заметки") {
                Button("Искать транзакции по заметке по строке: \"\(searchText)\"") {
                    filters.searchText = searchText
                }
                .disabled(searchText.isEmpty)
            }
            CollapsibleFilterSection(
                title: "Валюты",
                count: searchText.isEmpty ? nil : vm.currencies.filter { !filters.currencies.contains($0) }.count
            ) {
                if !searchText.isEmpty {
                    ForEach(vm.currencies.filter { !filters.currencies.contains($0) }) { currency in
                        Button(currency.name) {
                            filters.currencies.append(currency)
                        }
                    }
                } else {
                    Text("Начните вводить для поиска валют")
                        .foregroundStyle(.secondary)
                }
            }
            CollapsibleFilterSection(
                title: "Подкатегории",
                count: searchText.isEmpty ? nil : vm.tags.filter { !filters.tags.contains($0) && !filters.excludedTags.contains($0) }.count
            ) {
                if !searchText.isEmpty {
                    ForEach(vm.tags.filter { !filters.tags.contains($0) && !filters.excludedTags.contains($0) }) { tag in
                        FilterableTagRow(tag: tag, showAccountGroup: filters.accountGroups.count != 1) {
                            filters.tags.append(tag)
                            chartType = .earningsAndExpenses
                        } onExclude: {
                            filters.excludedTags.append(tag)
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
                alert.error(error)
            }
        }
        .onChange(of: searchText) { _, _ in
            Task {
                do {
                    try await vm.load(filters: filters, searchText: searchText)
                } catch {
                    alert.error(error)
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Транзакции")
    }
}

#Preview {
    TransactionsList(
        filters: TransactionFilters(accountGroups: []),
        vm: .constant(TransactionsListViewModel())
    )
    .environment(AlertManager(handle: {_ in }))
}




