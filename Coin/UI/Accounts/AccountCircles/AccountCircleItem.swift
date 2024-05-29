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

struct AccountCircleItem: View {
    
    var account: Account
    
    @Environment(\.dismiss) var dismiss
    @State var isChildrenOpen = false
    @State var isTransactionOpen = false
    @Environment(PathSharedState.self) var path
    var isAlreadyOpened: Bool
    
    var formatter: CurrencyFormatter
    
    init(
        _ account: Account,
        isAlreadyOpened: Bool = false
    ) {
        self.formatter = CurrencyFormatter(currency: account.currency)
        self.account = account
        if account.type == .balancing && account.showingRemainder < 0 && account.isParent {
            self.account.showingRemainder *= -1
        }
        self.isAlreadyOpened = isAlreadyOpened
    }
    
    
    var body: some View {
        VStack {
            Text(account.name)
                .lineLimit(1)
            ZStack {
                if account.isParent && account.type != .balancing {
                    Circle()
                        .fill(.clear)
                        .strokeBorder(account.showingBudgetAmount == 0 ? .gray : account.showingBudgetAmount >= account.showingRemainder ? .green : .red, lineWidth: 1)
                        .frame(width: 35)
                }
                Circle()
                    .fill(account.showingBudgetAmount == 0 ? .gray : account.showingBudgetAmount >= account.showingRemainder ? .green : .red)
                    .frame(width: 30)
                AsyncImage(url: URL.documentsDirectory.appending(path: account.icon.url)) { image in
                    image.image?
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20)
                }
            }
            .frame(height: 40)
            Text(formatter.string(number: account.showingRemainder))
                .lineLimit(1)
            
            Text(account.showingBudgetAmount != 0 ? formatter.string(number: account.showingBudgetAmount) : " ")
                .lineLimit(1)
                .foregroundColor(.secondary)
        }
        .onTapGesture(count: 2) {
            if !account.childrenAccounts.isEmpty {
                isChildrenOpen = true
            }
        }
        .onTapGesture(count: 1) {
            if isAlreadyOpened {
                dismiss()
            }
            path.path.append(AccountCircleItemRoute.accountTransactions(account))
        }
        .onLongPressGesture {
            if isAlreadyOpened {
                dismiss()
            }
            path.path.append(AccountCircleItemRoute.editAccount(account))
        }

        .font(.caption)
        .frame(width: 80, height: 100)
        .opacity(account.accountingInHeader ? 1 : 0.5)
        .popover(isPresented: $isChildrenOpen) {
            ScrollView {
                ForEach(account.childrenAccounts) { account in
                    AccountCircleItem(
                        account,
                        isAlreadyOpened: true
                    )
                }
                .presentationCompactAdaptation(.popover)
                .padding()
            }
        }
    }
}

#Preview {
    AccountCircleItem(Account())
        .environment(AlertManager(handle: {_ in }))
}
