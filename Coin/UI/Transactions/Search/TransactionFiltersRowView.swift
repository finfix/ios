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
                        Button {
                            filters.accountGroups.remove(at: i)
                        } label: {
                            TransactionFiltersRowItem(text: accountGroup.name, color: Color.orange)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if !filters.accounts.isEmpty {
                    ForEach(Array(zip(filters.accounts.indices, filters.accounts)), id: \.0) { i, account in
                        Button {
                            filters.accounts.remove(at: i)
                        } label: {
                            TransactionFiltersRowItem(text: account.name, color: Color.yellow)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if let dateFrom = filters.dateFrom {
                    Button {
                        filters.dateFrom = nil
                    } label: {
                        TransactionFiltersRowItem(text: "C \(dateFrom.formatted(date: .abbreviated, time: .omitted))", color: Color.blue)
                    }
                    .buttonStyle(.plain)
                }
                if let dateTo = filters.dateTo {
                    Button {
                        filters.dateTo = nil
                    } label: {
                        TransactionFiltersRowItem(text: "По \(dateTo.formatted(date: .abbreviated, time: .omitted))", color: Color.blue)
                    }
                    .buttonStyle(.plain)
                }
                if !filters.transactionTypes.isEmpty {
                    ForEach(Array(zip(filters.transactionTypes.indices, filters.transactionTypes)), id: \.0) { i, transactionType in
                        Button {
                            filters.transactionTypes.remove(at: i)
                        } label: {
                            TransactionFiltersRowItem(text: transactionType.name, color: Color.red)
                        }
                    }
                    .buttonStyle(.plain)
                }
                if !filters.currencies.isEmpty {
                    ForEach(Array(zip(filters.currencies.indices, filters.currencies)), id: \.0) { i, currency in
                        Button {
                            filters.currencies.remove(at: i)
                        } label: {
                            TransactionFiltersRowItem(text: currency.name, color: Color.purple)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if !filters.searchText.isEmpty {
                    Button {
                        filters.searchText = ""
                    } label: {
                        TransactionFiltersRowItem(text: "Заметка: \"\(filters.searchText)\"", color: Color.green)
                    }
                    .buttonStyle(.plain)
                }
                if !filters.tags.isEmpty {
                    ForEach(Array(zip(filters.tags.indices, filters.tags)), id: \.0) { i, tag in
                        Button {
                            filters.tags.remove(at: i)
                        } label: {
                            TransactionFiltersRowItem(text: tag.name, color: Color.brown)
                        }
                        .buttonStyle(.plain)
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
    
    var body: some View {
        HStack {
            Text(text)
            Button {
                
            } label: {
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
