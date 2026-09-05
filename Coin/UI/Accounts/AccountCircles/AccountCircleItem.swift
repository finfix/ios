//
//  AccountCircle.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI





struct AccountCircleItem: View {
    
    var account: Account
    
    @State var isTransactionOpen = false
    @Binding var path: NavigationPath
    @State var isChildrenOpen = false
    @Environment(\.dismiss) var dismiss
    var isAlreadyOpened: Bool = false
    
    var body: some View {
        VStack {
            AccountCircleItemHeader(account: account)
            AccountCircleItemCircle(account: account)
            AccountCircleItemFooter(account: account)
        }
        .gesture(
            LongPressGesture(minimumDuration: 1)
                .onEnded { state in
                    path.append(AccountCircleItemRoute.editAccount(account))
                    if isAlreadyOpened {
                        dismiss()
                    }
                }
        )
        .gesture(
            TapGesture(count: 2)
                .onEnded {
                    if !account.childrenAccounts.isEmpty {
                        isChildrenOpen = true
                    }
                }
        )
        .gesture(
            TapGesture(count: 1)
                .onEnded {
                    if isAlreadyOpened {
                        dismiss()
                    }
                    
                    var chartType: ChartType = .earningsAndExpenses
                    switch account.type {
                    case .earnings:
                        chartType = .earnings
                    case .expense:
                        chartType = .expenses
                    default: break
                    }
                    
                    path.append(AccountCircleItemRoute.accountTransactions(account, chartType))
                }
        )
        .popover(isPresented: $isChildrenOpen) {
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(account.childrenAccounts) { account in
                        AccountCircleItem(
                            account: account,
                            path: $path,
                            isAlreadyOpened: true
                        )
                        .frame(width: 80)
                    }
                    .presentationCompactAdaptation(.popover)
                }
                .padding()
            }
        }
        .opacity(account.accountingInHeader ? 1 : 0.5)
    }
}

#Preview {
    AccountCircleItem(
        account: Account(
            accountingInHeader: true,
            icon: Icon(url: "dollar.png"),
            name: "Имя счета",
            remainder: 10,
            showingRemainder: 10,
            type: .expense,
            visible: true,
            isParent: true,
            budgetAmount: 20,
            showingBudgetAmount: 20,
            currency: Currency(symbol: "$")
        ),
        path: .constant(NavigationPath())
    )
    .environment(AlertManager(handle: {_ in }))
}
