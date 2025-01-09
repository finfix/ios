//
//  TransactionFilterView.swift
//  Coin
//
//  Created by Илья on 03.11.2023.
//

import SwiftUI

struct TransactionFilterView: View {
    
    @Environment(\.dismiss) var dissmiss
    @Environment(AlertManager.self) var alert
    @State private var vm = TransactionFilterViewModel()
    @State private var shouldShowDateFrom = false
    @State private var shouldShowDateTo = false
    @Binding var filters: TransactionFilters
    
    var body: some View {
        Form {
            Section {
                Label("Дата", systemImage: "calendar")
                ExpandableDatePicker(buttonName: "C", isCalendarShowing: $shouldShowDateFrom, date: $filters.dateFrom)
                ExpandableDatePicker(buttonName: "По", isCalendarShowing: $shouldShowDateTo, date: $filters.dateTo)
            }
            Section {
                Picker("Тип транзакции", selection: $filters.transactionType) {
                    Text("Тип не выбран")
                        .tag(nil as TransactionType?)
                    ForEach(TransactionType.allCases, id: \.rawValue) { type in
                        Text(type.rawValue)
                            .tag(type as TransactionType?)
                    }
                }
                .pickerStyle(.menu)
            }
            if !filters.accountGroups.isEmpty {
                Section(header: Text("Группы счетов")) {
                    List {
                        ForEach(Array(zip(filters.accountGroups.indices, filters.accountGroups)), id: \.0) { i, accountGroup in
                            HStack {
                                Text(accountGroup.name)
                                Spacer()
                                Button {
                                    filters.accountGroups.remove(at: i)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                            }
                        }
                        .onDelete { i in
                            filters.accountGroups.remove(atOffsets: i)
                        }
                    }
                }
            }
            if !filters.accounts.isEmpty {
                Section(header: Text("Счета")) {
                    List {
                        ForEach(Array(zip(filters.accounts.indices, filters.accounts)), id: \.0) { i, account in
                            HStack {
                                Text(account.name)
                                Spacer()
                                Button {
                                    filters.accounts.remove(at: i)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                            }
                        }
                        .onDelete { i in
                            filters.accounts.remove(atOffsets: i)
                        }
                    }
                }
            }
            if !filters.searchText.isEmpty {
                Section(header: Text("Заметка")) {
                    HStack {
                        Text(filters.searchText)
                        Spacer()
                        Button {
                            filters.searchText.removeAll()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                    }
                }
            }
            Section {
                Picker("Валюта транзакции", selection: $filters.currency) {
                    Text("Валюта не выбрана")
                        .tag(nil as Currency?)
                    ForEach(vm.currencies) { currency in
                        Text(currency.name)
                            .tag(currency as Currency?)
                    }
                }
            }
        }
        .task {
            do {
                try await vm.load()
            } catch {
                alert(error)
            }
        }
        .datePickerStyle(.graphical)
        .navigationTitle("Фильтры")
        .navigationBarTitleDisplayMode(.inline)
    }
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

#Preview {
    TransactionFilterView(
        filters: .constant(TransactionFilters())
    )
    .environment(AlertManager(handle: {_ in }))
}
