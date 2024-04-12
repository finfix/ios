//
//  AccountCircle.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct AccountCircleItem: View {
    
    var account: Account
    
    @Environment(\.dismiss) var dismiss
    @State var isChildrenOpen = false
    @State var isTransactionOpen = false
    @Binding var path: NavigationPath
    @Binding var selectedAccountGroup: AccountGroup
    var isAlreadyOpened: Bool
    
    var formatter: CurrencyFormatter
    
    init(
        _ account: Account,
        isAlreadyOpened: Bool = false,
        path: Binding<NavigationPath>,
        selectedAccountGroup: Binding<AccountGroup>
    ) {
        self.formatter = CurrencyFormatter(currency: account.currency)
        self.account = account
        if account.type == .balancing && account.remainder < 0 && account.isParent {
            self.account.remainder *= -1
        }
        self.isAlreadyOpened = isAlreadyOpened
        self._path = path
        self._selectedAccountGroup = selectedAccountGroup
    }
    
    
    var body: some View {
        VStack {
            Text(account.name)
                .lineLimit(1)
            ZStack {
                if account.isParent && account.type != .balancing {
                    Circle()
                        .fill(.clear)
                        .strokeBorder(account.showingBudgetAmount == 0 ? .gray : account.showingBudgetAmount >= account.remainder ? .green : .red, lineWidth: 1)
                        .frame(width: 35)
                }
                Circle()
                    .fill(account.showingBudgetAmount == 0 ? .gray : account.showingBudgetAmount >= account.remainder ? .green : .red)
                    .frame(width: 30)
            }
            Text(formatter.string(number: account.remainder))
                .lineLimit(1)
            
            if account.showingBudgetAmount != 0 {
                Text(formatter.string(number: account.showingBudgetAmount))
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
        }
        .onTapGesture(count: 2) {
            if !account.childrenAccounts.isEmpty {
                isChildrenOpen = true
            }
        }
//        .onTapGesture(count: 1) {
//            isTransactionOpen = true
//        }
        .onLongPressGesture {
            if isAlreadyOpened {
                dismiss()
            }
            path.append(account)
        }

        .font(.caption)
        .frame(width: 80, height: 100)
        .opacity(account.accounting ? 1 : 0.5)
        .popover(isPresented: $isChildrenOpen) {
            ScrollView {
                ForEach(account.childrenAccounts) { account in
                    AccountCircleItem(account, 
                                      isAlreadyOpened: true,
                                      path: $path,
                                      selectedAccountGroup: $selectedAccountGroup)
                }
                .presentationCompactAdaptation(.popover)
                .padding()
            }
        }
        .navigationDestination(isPresented: $isTransactionOpen) {
            TransactionsView(selectedAccountGroup: $selectedAccountGroup, account: account)
        }
    }
}

#Preview {
    AccountCircleItem(Account(), path: .constant(NavigationPath()), selectedAccountGroup: .constant(AccountGroup()))
}
