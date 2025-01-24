//
//  AccountCircleView.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI
import OSLog
import Factory

private let logger = Logger(subsystem: "Coin", category: "AccountCirclesView")

enum DraggableAccountRoute: Hashable {
case createTransaction(TransactionType, Account, Account)
}

struct AccountCirclesView: View {
    
    @Environment(AlertManager.self) private var alert
    @Environment(AccountGroupSharedState.self) private var selectedAccountGroup
    @State private var path = PathSharedState()
    @State private var vm = AccountCirclesViewModel()
    
    let horizontalSpacing: CGFloat = 10
    
    var body: some View {
        NavigationStack(path: $path.path) {
            QuickStatisticView(selectedAccountGroup: selectedAccountGroup.selectedAccountGroup)
            ZStack {
                VStack {
                    ScrollView(.horizontal) {
                        HStack(spacing: horizontalSpacing) {
                            ForEach(vm.accounts.filter { $0.type == .earnings || ($0.type == .balancing && $0.showingRemainder > 0) }) { account in
                                DraggableAccountCircleItem(vm: $vm, accountGroup: selectedAccountGroup.selectedAccountGroup, account: account, path: $path.path)
                            }
                            PlusNewAccount(accountType: .earnings)
                        }
                    }
                    
                    Divider()
                    
                    ScrollView(.horizontal) {
                        HStack(spacing: horizontalSpacing) {
                            ForEach(vm.accounts.filter { $0.type == .regular }) { account in
                                DraggableAccountCircleItem(vm: $vm, accountGroup: selectedAccountGroup.selectedAccountGroup, account: account, path: $path.path)
                            }
                            PlusNewAccount(accountType: .regular)
                        }
                    }
                    
                    Divider()
                    
                    ScrollView(.horizontal) {
                        LazyHGrid(rows: [GridItem(.adaptive(minimum: 100))], alignment: .top, spacing: horizontalSpacing) {
                            ForEach(vm.accounts.filter { $0.type == .expense }) { account in
                                DraggableAccountCircleItem(vm: $vm, accountGroup: selectedAccountGroup.selectedAccountGroup, account: account, path: $path.path)
                            }
                            PlusNewAccount(accountType: .expense)
                        }
                    }
                }
                .contentMargins(.horizontal, horizontalSpacing, for: .scrollContent)
                .scrollIndicators(.hidden)
                if let draggableLocation = vm.draggableLocation {
                    ZStack {
                        Circle()
                            .fill(.orange)
                            .frame(width: 70, height: 70)
                            .shadow(radius: 10)
                        if let draggableAccount = vm.draggableAccount {
                            AsyncImage(url: URL.documentsDirectory.appending(path: draggableAccount.icon.url)) { image in
                                image.image?
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50)
                            }
                        }
                    }
                    .position(draggableLocation)
                }
            }
            .coordinateSpace(name: "OuterV")
            .task {
                vm.draggableLocation = nil
                do {
                    try await vm.load(accountGroup: selectedAccountGroup.selectedAccountGroup)
                } catch {
                    alert(error)
                }
            }
            .onChange(of: selectedAccountGroup.selectedAccountGroup) { _, _ in
                Task {
                    do {
                        try await vm.load(accountGroup: selectedAccountGroup.selectedAccountGroup)
                    } catch {
                        alert(error)
                    }
                }
                vm.deleteStaticLocations()
            }
            .navigationDestination(for: AccountCircleItemRoute.self) { screen in
                switch screen {
                case .accountTransactions(let account, let chartType): TransactionsView(filters: TransactionFilters(accounts: [account]), chartType: chartType)
                case .editAccount(let account): EditAccount(account, selectedAccountGroup: selectedAccountGroup.selectedAccountGroup, isHiddenView: false)
                }
            }
            .navigationDestination(for: PlusNewAccountRoute.self) { screen in
                switch screen {
                case .createAccount(let accountType): EditAccount(accountType: accountType, accountGroup: selectedAccountGroup.selectedAccountGroup)
                }
            }
            .navigationDestination(for: TransactionsListRoute.self) { screen in
                switch screen {
                case .editTransaction(let transaction): EditTransaction(transaction)
                }
            }
            .navigationDestination(for: EditTransactionRoute.self) { screen in
                switch screen {
                case .tagsList:
                    TagsList(accountGroup: selectedAccountGroup.selectedAccountGroup)
                }
            }
            .navigationDestination(for: TagsListRoute.self) { screen in
                switch screen {
                case .createTag:
                    EditTag(selectedAccountGroup: selectedAccountGroup.selectedAccountGroup)
                case .editTag(let tag):
                    EditTag(tag)
                }
            }
            .navigationDestination(for: ChartViewRoute.self) { screen in
                switch screen {
                case .transactionView(let filters, let chartType):
                    TransactionsView(filters: filters, chartType: chartType)
                }
            }
            .navigationDestination(for: DraggableAccountRoute.self) { screen in
                switch screen {
                case .createTransaction(let transactionType, let accountFrom, let accountTo): 
                    EditTransaction(
                        transactionType: transactionType,
                        accountFrom: accountFrom,
                        accountTo: accountTo,
                        accountGroup: selectedAccountGroup.selectedAccountGroup
                    )
                }
            }
        }
        .environment(path)
    }
}

#Preview {
    AccountCirclesView()
        .environment(AlertManager(handle: {_ in }))
}
