//
//  AccountCircle.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct AccountCircleItem: View {
    
    var account: Account
    
    @Environment(ModelData.self) var modelData
    
    @State var isChildrenOpen = false
    @State var isUpdateOpen = false
    
    var currencySymbol: String {
        modelData.currencies[account.currency]?.symbol ?? ""
    }
    
    var formatter: CurrencyFormatter
    
    init(account: Account, alreadyOpened: Bool = false) {
        self.formatter = CurrencyFormatter(currency: account.currency)
        self.account = account
        self.alreadyOpened = alreadyOpened
    }
    
    var body: some View {
        
        VStack {
            Text(account.name)
                .lineLimit(1)
            
            Circle()
                .frame(width: 30)
                .foregroundColor(account.budget == 0 ? .gray : account.budget >= account.remainder ? .green : .red)
                .onTapGesture {
                    isChildrenOpen = true
                }
                .onLongPressGesture(minimumDuration: 1.0) {
                    isUpdateOpen = true
                }
            
            Text(formatter.string(number: account.remainder))
                .lineLimit(1)
            
            if account.budget != 0 {
                Text(formatter.string(number: account.budget))
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
        }
        .font(.caption)
        .frame(width: 80, height: 100)
        .popover(isPresented: $isChildrenOpen) {
            if account.childrenAccounts.count > 0 {
                AccountChildren(children: account.childrenAccounts)
                .padding()
                .presentationCompactAdaptation(.popover)
            }
        }
        .navigationDestination(isPresented: $isUpdateOpen) {
            UpdateAccount(isUpdateOpen: $isUpdateOpen, account: account)
        }
        .navigationDestination(isPresented: $isTransactionListOpen) {
            TransactionsList(filteredAccountID: account.id)
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
                parentAccountID: nil)]))
}
