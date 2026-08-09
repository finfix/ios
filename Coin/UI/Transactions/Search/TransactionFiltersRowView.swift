//
//  TransactionFilterView.swift
//  Coin
//
//  Created by Илья on 03.11.2023.
//

import SwiftUI

struct TransactionFiltersRowView: View {

    @Binding var filters: TransactionFilters

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                if !filters.accountGroups.isEmpty {
                    ForEach(Array(zip(filters.accountGroups.indices, filters.accountGroups)), id: \.0) { i, accountGroup in
                        TransactionFiltersRowItem(text: accountGroup.name, color: Color.orange) {
                            filters.accountGroups.remove(at: i)
                        }
                    }
                }
                if !filters.accounts.isEmpty {
                    ForEach(Array(zip(filters.accounts.indices, filters.accounts)), id: \.0) { i, account in
                        TransactionFiltersRowItem(text: "\(account.name) · \(account.accountGroup.name)", color: Color.yellow) {
                            filters.accounts.remove(at: i)
                        }
                    }
                }
                if !filters.excludedAccounts.isEmpty {
                    ForEach(Array(zip(filters.excludedAccounts.indices, filters.excludedAccounts)), id: \.0) { i, account in
                        TransactionFiltersRowItem(text: "Искл.: \(account.name) · \(account.accountGroup.name)", color: Color.gray) {
                            filters.excludedAccounts.remove(at: i)
                        }
                    }
                }
                if let dateFrom = filters.dateFrom {
                    TransactionFiltersRowItem(text: "C \(dateFrom.formatted(date: .abbreviated, time: .omitted))", color: Color.blue) {
                        filters.dateFrom = nil
                    }
                }
                if let dateTo = filters.dateTo {
                    TransactionFiltersRowItem(text: "По \(dateTo.formatted(date: .abbreviated, time: .omitted))", color: Color.blue) {
                        filters.dateTo = nil
                    }
                }
                if !filters.transactionTypes.isEmpty {
                    ForEach(Array(zip(filters.transactionTypes.indices, filters.transactionTypes)), id: \.0) { i, transactionType in
                        TransactionFiltersRowItem(text: transactionType.name, color: Color.red) {
                            filters.transactionTypes.remove(at: i)
                        }
                    }
                }
                if !filters.currencies.isEmpty {
                    ForEach(Array(zip(filters.currencies.indices, filters.currencies)), id: \.0) { i, currency in
                        TransactionFiltersRowItem(text: currency.name, color: Color.purple) {
                            filters.currencies.remove(at: i)
                        }
                    }
                }
                if !filters.searchText.isEmpty {
                    TransactionFiltersRowItem(text: "Заметка: \"\(filters.searchText)\"", color: Color.green) {
                        filters.searchText = ""
                    }
                }
                if !filters.tags.isEmpty {
                    ForEach(Array(zip(filters.tags.indices, filters.tags)), id: \.0) { i, tag in
                        TransactionFiltersRowItem(text: tag.name, color: Color.brown) {
                            filters.tags.remove(at: i)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct TransactionFiltersRowItem: View {

    var text: String
    var color: Color
    var onRemove: () -> Void

    var body: some View {
        HStack {
            Text(text)
            Button(action: onRemove) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
        }
            .font(.callout)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                RoundedRectangle(cornerRadius: 100)
                    .foregroundStyle(color)
            }
    }
}



#Preview {
    TransactionFiltersRowView(
        filters: .constant(TransactionFilters(accountGroups: []))
    )
}
