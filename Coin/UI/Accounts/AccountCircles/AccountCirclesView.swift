//
//  AccountCircleView.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "AccountCirclesView")

enum DraggableAccountRoute: Hashable {
case createTransaction(TransactionType, Account, Account)
}

struct AccountCirclesView: View {
    
    @Environment (AlertManager.self) private var alert
    @Environment(AccountGroupSharedState.self) var selectedAccountGroup
    @State var path = PathSharedState()
    @StateObject var vm = AccountCirclesViewModel()
    
    let horizontalSpacing: CGFloat = 10
    
    var groupedAccounts: [Account] {
        Account.groupAccounts(vm.accounts.filter {
            $0.accountGroup == selectedAccountGroup.selectedAccountGroup
        })
    }
    
    var body: some View {
        NavigationStack(path: $path.path) {
            VStack(spacing: 0) {
                QuickStatisticView(selectedAccountGroup: selectedAccountGroup.selectedAccountGroup)
                AccountGroupSelector()
            }
            ZStack {
                VStack {
                    ScrollView(.horizontal) {
                        HStack(spacing: horizontalSpacing) {
                            ForEach(groupedAccounts.filter { $0.type == .earnings || ($0.type == .balancing && $0.showingRemainder > 0) }) { account in
                                DraggableAccountCircleItem(vm: vm, account: account, path: $vm.path)
                            }
                            PlusNewAccount(accountType: .earnings)
                        }
                    }
                    
                    Divider()
                    
                    ScrollView(.horizontal) {
                        HStack(spacing: horizontalSpacing) {
                            ForEach(groupedAccounts.filter { $0.type == .regular }) { account in
                                DraggableAccountCircleItem(vm: vm, account: account, path: $vm.path)
                            }
                            PlusNewAccount(accountType: .regular)
                        }
                    }
                    
                    Divider()
                    
                    ScrollView(.horizontal) {
                        LazyHGrid(rows: [GridItem(.adaptive(minimum: 100))], alignment: .top, spacing: horizontalSpacing) {
                            ForEach(groupedAccounts.filter { $0.type == .expense || ($0.type == .balancing && $0.showingRemainder < 0)}) { account in
                                DraggableAccountCircleItem(vm: vm, account: account, path: $vm.path)
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
                Group {
                    ForEach(vm.staticLocations.sorted(by: { _,_ in true }), id: \.key.id) { (account, location) in
                        ZStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 50, height: 50)
                            Text(account.name)
                        }
                        .opacity(0.5)
                        .position(location)
                    }
                }
            }
            .coordinateSpace(name: "OuterV")
            .task {
                vm.draggableLocation = nil
                do {
                    try await vm.load()
                } catch {
                    alert(error)
                }
            }
            .navigationDestination(for: AccountCircleItemRoute.self) { screen in
                switch screen {
                case .accountTransactions(let account): TransactionsView(account: account)
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
                case .transactionList(account: let account):
                    TransactionsView(account: account)
                case .transactionList1(chartType: let chartType):
                    TransactionsView(chartType: chartType)
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
