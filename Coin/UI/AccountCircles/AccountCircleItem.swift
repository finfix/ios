//
//  AccountCircle.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI
import SwiftData

struct AccountCircleItem: View {
    
    var account: Account
    
    @Environment(\.dismiss) var dismiss
    @Query var currencies: [Currency]
    @State var isChildrenOpen = false
    @State var isTransactionOpen = false
    @Binding var path: NavigationPath
    var isAlreadyOpened: Bool
        
    var currenciesMap: [String: Currency] {
        Dictionary(uniqueKeysWithValues: currencies.map{ ($0.isoCode, $0) })
    }
    
    var currencySymbol: String {
        currenciesMap[account.currency]?.symbol ?? ""
    }
    
    var formatter: CurrencyFormatter
    
    init(_ account: Account, isAlreadyOpened: Bool = false, path: Binding<NavigationPath>) {
        self.formatter = CurrencyFormatter(currency: account.currency)
        self.account = account
        self.isAlreadyOpened = isAlreadyOpened
        self._path = path
    }
    
    
    var body: some View {
        VStack {
            Text(account.name)
                .lineLimit(1)
            ZStack {
                if !account.childrenAccounts.isEmpty {
                    Circle()
                        .fill(.clear)
                        .strokeBorder(account.showingBudget == 0 ? .gray : account.showingBudget >= account.showingRemainder ? .green : .red, lineWidth: 1)
                        .frame(width: 35)
                }
                Circle()
                    .fill(account.showingBudget == 0 ? .gray : account.showingBudget >= account.showingRemainder ? .green : .red)
                    .frame(width: 30)
            }
            .onTapGesture(count: 2) {
                if !account.childrenAccounts.isEmpty {
                    isChildrenOpen = true
                }
            }
            .onTapGesture(count: 1) {
                isTransactionOpen = true
            }
            .onLongPressGesture {
                if isAlreadyOpened {
                    dismiss()
                }
                path.append(account)
            }
            Text(formatter.string(number: account.showingRemainder))
                .lineLimit(1)
            
            if account.showingBudget != 0 {
                Text(formatter.string(number: account.showingBudget))
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
        }
        .font(.caption)
        .frame(width: 80, height: 100)
        .opacity(account.accounting ? 1 : 0.5)
        .popover(isPresented: $isChildrenOpen) {
            ForEach(account.childrenAccounts) { account in
                AccountCircleItem(account, isAlreadyOpened: true, path: $path)
            }
            .presentationCompactAdaptation(.popover)
            .padding()
        }
        .navigationDestination(isPresented: $isTransactionOpen) {
            TransactionsView(accountID: account.id)
        }
    }
}

#Preview {
    AccountCircleItem(account: Account(
        id: 1,
        accountGroupID: 1,
        accounting: true,
        budget: 49,
        currency: "RUB",
        iconID: 1,
        name: "parent",
        remainder: 34,
        type: .expense,
        visible: true,
        parentAccountID: nil,
        childrenAccounts: [
            Account(
                id: 2,
                accountGroupID: 1,
                accounting: true,
                budget: 0,
                currency: "RUB",
                iconID: 1,
                name: "child",
                remainder: 43,
                type: .expense,
                visible: true,
                parentAccountID: nil),
            Account(
                id: 3,
                accountGroupID: 1,
                accounting: true,
                budget: 34,
                currency: "RUB",
                iconID: 1,
                name: "child",
                remainder: 43,
                type: .expense,
                visible: true,
                parentAccountID: nil),
            Account(
                id: 4,
                accountGroupID: 1,
                accounting: true,
                budget: 34,
                currency: "RUB",
                iconID: 1,
                name: "child",
                remainder: 43,
                type: .expense,
                visible: true,
                parentAccountID: nil)]),
                      path: .constant(NavigationPath()))
}
