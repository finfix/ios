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
    
    @State var isTransactionOpen = false
    @Environment(PathSharedState.self) var path
    
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
    }
    
    
    var body: some View {
        VStack {
            Text(account.name)
                .lineLimit(1)
            
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
            
            Text(formatter.string(number: account.showingRemainder))
                .lineLimit(1)
            
            Text(account.showingBudgetAmount != 0 ? formatter.string(number: account.showingBudgetAmount) : " ")
                .lineLimit(1)
                .foregroundColor(.secondary)
        }
        .font(.caption)
        .opacity(account.accountingInHeader ? 1 : 0.5)
    }
}

#Preview {
    AccountCircleItem(
        Account(
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
        )
    )
    .environment(AlertManager(handle: {_ in }))
}
