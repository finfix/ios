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
    @Binding var dateFrom: Date?
    @Binding var dateTo: Date?
    @Binding var transactionType: TransactionType?
    @Binding var accountGroup: AccountGroup
    @Binding var currency: Currency?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Дата", systemImage: "calendar")
                    Сalendar(buttonName: "C", date: $dateFrom)
                    Сalendar(buttonName: "По", date: $dateTo)
                }
                Section {
                    Picker("Тип транзакции", selection: $transactionType) {
                        Text("Тип не выбран")
                            .tag(nil as TransactionType?)
                        ForEach(TransactionType.allCases, id: \.rawValue) { type in
                            Text(type.rawValue)
                                .tag(type as TransactionType?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section {
                    AccountGroupSelector(selectedAccountGroup: $accountGroup, pickerName: "Группа счетов")
                }
                Section {
                    Picker("Валюта транзакции", selection: $currency) {
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Готово") { dissmiss() }
                }
            }
        }
    }
}

private struct Сalendar: View {
    
    var buttonName: String
    @State private var isCalendarShowing = false
    @Binding var date: Date?
    
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
                if date != nil {
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
            }
        }
    }
}

#Preview {
    TransactionFilterView(
        dateFrom: .constant(Date()),
        dateTo: .constant(Date()),
        transactionType: .constant(TransactionType.balancing),
        accountGroup: .constant(AccountGroup()),
        currency: .constant(Currency())
    )
    .environment(AlertManager(handle: {_ in }))
}
