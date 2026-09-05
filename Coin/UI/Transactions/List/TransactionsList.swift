//
//  TransactionsList.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import SwiftUI


struct TransactionsList: View {
    
    @Environment(AlertManager.self) private var alert
    @Binding var vm: TransactionsListViewModel

    var filters: TransactionFilters

    @Environment(PathSharedState.self) var path

    @State private var offsets = [CGSize](repeating: CGSize.zero, count: 100)


    let width: CGFloat = UIScreen.main.bounds.width
    let height: CGFloat = UIScreen.main.bounds.height

    init(
        filters: TransactionFilters,
        vm: Binding<TransactionsListViewModel>
    ) {
        self.filters = filters
        self._vm = vm
    }
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(vm.transactionItems) { item in
                VStack(spacing: 0) {
                    Group {
                        if item.isNewSection {
                            HStack {
                                Text(item.transaction.dateTransaction.formatted(date: .complete, time: .omitted).uppercased())
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 30)
                                    .padding(.bottom, 10)
                                    .padding(.horizontal, 10)
                                Spacer()
                            }
                            Divider()
                        }
                    }
                    VStack(spacing: 0) {
                        Button {
                            Task {
                                do {
                                    guard let transaction = try await vm.fetchFullTransaction(id: item.id) else { return }
                                    path.path.append(TransactionsListRoute.editTransaction(transaction))
                                } catch {
                                    alert.error(error)
                                }
                            }
                        } label: {
                            TransactionRow(transaction: item.transaction)
                                .contentShape(Rectangle())
                        }
                        .padding(.horizontal)
                        .frame(minHeight: 55)
                        .buttonStyle(.plain)
                        Divider()
                    }
                    .background(Color(.systemGray6))
                    if let dailyExpenseTotal = item.dailyExpenseTotal, let dailyExpenseCurrency = item.dailyExpenseCurrency {
                        HStack {
                            Text("Расход за день")
                            Spacer()
                            Text(CurrencyFormatter(maximumFractionDigits: 7).string(number: dailyExpenseTotal, currency: dailyExpenseCurrency, withUnits: false))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                    }
                }
                // .id() на top-level элементе ForEach — ScrollViewReader.scrollTo и
                // .scrollPosition(id:) надёжно находят только id, поставленный так.
                .id(item.id)
                .transition(.opacity)
                .onAppear {
                    Task {
                        do {
                            try await vm.loadMoreIfNeeded(currentItem: item)
                        } catch {
                            alert.error(error)
                        }
                    }
                }
            }
            if vm.isLoadingNextPage {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            }
        }
        .task {
            do {
                try await vm.loadIfNeeded(filters: filters)
            } catch {
                alert.error(error)
            }
        }
        // Живая подписка на уже открытое пагинацией окно — фоновые изменения (incrementalSync,
        // другое устройство) видны сами, без pull-to-refresh. Переподписывается только когда
        // пагинация реально расширяет историю (см. oldestLoadedDate), не на каждое обновление
        // строк внутри уже открытого окна.
        .task(id: vm.oldestLoadedDate) {
            guard let observation = vm.observeLoadedWindow() else { return }
            do {
                for try await rows in observation {
                    withAnimation {
                        vm.applyObservedRows(rows)
                    }
                }
            } catch {
                alert.error(error)
            }
        }
        // pull-to-refresh остаётся как явный полный релоад (в т.ч. transactionDays для календаря).
        .refreshable {
            do {
                try await vm.load(filters: filters)
            } catch {
                alert.error(error)
            }
        }
        .onChange(of: filters) { _, _ in
            Task {
                do {
                    try await vm.load(filters: filters)
                } catch {
                    alert.error(error)
                }
            }
        }
    }
}

#Preview {
    TransactionsList(
        filters: TransactionFilters(accountGroups: []),
        vm: .constant(TransactionsListViewModel())
    )
    .environment(AlertManager(handle: {_ in }))
}
