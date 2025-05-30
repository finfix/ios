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

struct AccountsTabView: View {
    @Binding var vm: AccountCirclesViewModel
    @Binding var path: NavigationPath
    let accountGroup: AccountGroup
    let accounts: [Account]
    let accountType: AccountType
    let horizontalSpacing: CGFloat
    let minRows: Int?
    let maxRows: Int?
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > 0 && geometry.size.height > 0 {
                let itemWidth: CGFloat = 80
                let itemHeight: CGFloat = 120
                
                let columnsCount = max(1, Int(geometry.size.width / (itemWidth + horizontalSpacing)))
                let rowsCount = if let minRows {
                    minRows
                } else if let maxRows {
                    min(maxRows, Int(geometry.size.height / itemHeight))
                } else {
                    max(1, Int(geometry.size.height / itemHeight))
                }
                
                let itemsPerPage = columnsCount * rowsCount
                let pagesCount = max(1, Int(ceil(Double(accounts.count + 1) / Double(itemsPerPage))))
                
                let totalSpacing = geometry.size.width - (CGFloat(columnsCount) * itemWidth)
                let evenSpacing = totalSpacing / CGFloat(columnsCount + 1)
                
                TabView {
                    ForEach(0..<pagesCount, id: \.self) { pageIndex in
                        VStack {
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.fixed(itemWidth), spacing: evenSpacing), count: columnsCount),
                                spacing: horizontalSpacing
                            ) {
                                let startIndex = pageIndex * itemsPerPage
                                let endIndex = min(startIndex + itemsPerPage, accounts.count)
                                let pageAccounts = accounts[startIndex..<endIndex]
                                
                                ForEach(pageAccounts) { account in
                                    DraggableAccountCircleItem(vm: $vm, accountGroup: accountGroup, account: account, path: $path)
                                }
                                
                                if pageIndex == pagesCount - 1 {
                                    PlusNewAccount(accountType: accountType)
                                }
                            }
                            Spacer()
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            } else {
                Color.clear
            }
        }
    }
}

struct CoordinateGrid: View {
    let spacing: CGFloat = 10
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Вертикальные линии
            ForEach(0...Int(size.width/spacing), id: \.self) { i in
                let x = CGFloat(i) * spacing
                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                .stroke(Color.blue.opacity(0.2), lineWidth: 0.5)
                
                // Метки по X каждые 50 пикселей
                if i % 5 == 0 {
                    Text("\(Int(x))")
                        .font(.system(size: 8))
                        .position(x: x, y: 10)
                }
            }
            
            // Горизонтальные линии
            ForEach(0...Int(size.height/spacing), id: \.self) { i in
                let y = CGFloat(i) * spacing
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                .stroke(Color.blue.opacity(0.2), lineWidth: 0.5)
                
                // Метки по Y каждые 50 пикселей
                if i % 5 == 0 {
                    Text("\(Int(y))")
                        .font(.system(size: 8))
                        .position(x: 10, y: y)
                }
            }
        }
    }
}

struct AccountCirclesView: View {
    
    @Environment(AlertManager.self) private var alert
    @Environment(AccountGroupSharedState.self) private var selectedAccountGroup
    @State private var path = PathSharedState()
    @State private var vm = AccountCirclesViewModel()
    @State private var quickStatisticVM = QuickStatisticViewModel()
    @State private var dragLocation: CGPoint?
    
    let horizontalSpacing: CGFloat = 10
    
    var body: some View {
        NavigationStack(path: $path.path) {
            GeometryReader { geometry in
                ZStack {
                    VStack {
                        QuickStatisticView(selectedAccountGroup: selectedAccountGroup.selectedAccountGroup)
                        
                        let earningsAccounts = vm.accounts.filter { $0.type == .earnings || ($0.type == .balancing && $0.showingRemainder > 0) }
                        AccountsTabView(
                            vm: $vm,
                            path: $path.path,
                            accountGroup: selectedAccountGroup.selectedAccountGroup,
                            accounts: earningsAccounts,
                            accountType: .earnings,
                            horizontalSpacing: horizontalSpacing,
                            minRows: 1,
                            maxRows: nil
                        )
                        .frame(height: 120)
                        
                        Divider()
                        
                        let regularAccounts = vm.accounts.filter { $0.type == .regular }
                        AccountsTabView(
                            vm: $vm,
                            path: $path.path,
                            accountGroup: selectedAccountGroup.selectedAccountGroup,
                            accounts: regularAccounts,
                            accountType: .regular,
                            horizontalSpacing: horizontalSpacing,
                            minRows: 1,
                            maxRows: nil
                        )
                        .frame(height: 120)
                        
                        Divider()
                        
                        let expenseAccounts = vm.accounts.filter { $0.type == .expense }
                        AccountsTabView(
                            vm: $vm,
                            path: $path.path,
                            accountGroup: selectedAccountGroup.selectedAccountGroup,
                            accounts: expenseAccounts,
                            accountType: .expense,
                            horizontalSpacing: horizontalSpacing,
                            minRows: nil,
                            maxRows: nil
                        )
                        .frame(maxHeight: .infinity)
                    }
                    .contentMargins(.horizontal, horizontalSpacing, for: .scrollContent)
                    .scrollIndicators(.hidden)
                    
                    if let draggableLocation = vm.draggableLocation {
                        Circle()
                            .fill(.orange)
                            .frame(width: 70, height: 70)
                            .shadow(radius: 10)
                            .overlay {
                                if let draggableAccount = vm.draggableAccount {
                                        AsyncImage(url: URL.documentsDirectory.appending(path: draggableAccount.icon.url)) { image in
                                            image.image?
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 50)
                                        }
                                    }
                            }
                            .position(CGPoint(
                                x: draggableLocation.x,
                                y: draggableLocation.y - geometry.safeAreaInsets.top
                            ))
                    }
                }
            }
            .task {
                vm.draggableLocation = nil
                do {
                    try await vm.load(accountGroup: selectedAccountGroup.selectedAccountGroup)
                    try await quickStatisticVM.load()
                } catch {
                    alert(error)
                }
            }
            .onChange(of: selectedAccountGroup.selectedAccountGroup) { _, _ in
                vm.deleteStaticLocations()
                Task {
                    do {
                        try await vm.load(accountGroup: selectedAccountGroup.selectedAccountGroup)
                        try await quickStatisticVM.load()
                    } catch {
                        alert(error)
                    }
                }
            }
            .navigationDestination(for: AccountCircleItemRoute.self) { screen in
                switch screen {
                case .accountTransactions(let account, let chartType): TransactionsView(
                    filters: TransactionFilters(
                        accounts: [account],
                        accountGroups: [account.accountGroup]
                    ),
                    chartType: chartType)
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
