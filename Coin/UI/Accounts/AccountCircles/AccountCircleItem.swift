//
//  AccountCircle.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

enum AccountCircleItemRoute: Hashable {
    case editAccount(Account)
    case accountTransactions(Account)
}

struct AccountCircleItemHeader: View {
    
    var account: Account
    
    var body: some View {
        Text(account.name)
            .lineLimit(1)
            .font(.caption)
    }
}

struct AccountCircleItemCircle: View {
    
    var account: Account
    
    var body: some View {
        ZStack {
            if account.isParent && account.type != .balancing {
                Circle()
                    .fill(.clear)
                    .strokeBorder(account.showingBudgetAmount == 0 ? .gray : account.showingBudgetAmount >= account.showingRemainder ? .green : .red, lineWidth: 2)
                    .frame(width: 46)
            }
            Circle()
                .fill(account.showingBudgetAmount == 0 ? .gray : account.showingBudgetAmount >= account.showingRemainder ? .green : .red)
                .frame(width: 40)
            AsyncImage(url: URL.documentsDirectory.appending(path: account.icon.url)) { image in
                image.image?
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25)
            }
        }
        .frame(height: 50)
    }
}

struct AccountCircleItemFooter: View {
    
    var formatter: CurrencyFormatter
    var account: Account
    
    init(account: Account) {
        self.formatter = CurrencyFormatter(currency: account.currency)
        self.account = account
        if account.type == .balancing && account.showingRemainder < 0 && account.isParent {
            self.account.showingRemainder *= -1
        }
    }
    
    var body: some View {
        Text(formatter.string(number: account.showingRemainder))
            .lineLimit(1)
            .font(.caption)
        
        Text(account.showingBudgetAmount != 0 ? formatter.string(number: account.showingBudgetAmount) : " ")
            .lineLimit(1)
            .foregroundColor(.secondary)
            .font(.caption)
    }
}

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
                    path.append(AccountCircleItemRoute.accountTransactions(account))
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
