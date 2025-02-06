//
//  AccountCircle.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

enum AccountCircleItemRoute: Hashable {
    case editAccount(Account)
    case accountTransactions(Account, ChartType)
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
    
    var objectColor: LinearGradient {
        switch account.type {
        case .balancing:
            return LinearGradient(
                gradient: Gradient(colors: [.yellow]),
                startPoint: .top,
                endPoint: .bottom
            )
        case .debt, .regular:
            return LinearGradient(
                gradient: Gradient(colors: [.orange]),
                startPoint: .top,
                endPoint: .bottom
            )
        case .expense:
            switch true {
            case account.showingBudgetAmount == 0:
                return LinearGradient(
                    gradient: Gradient(colors: [.green]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            case account.showingBudgetAmount >= account.showingRemainder:
                
                let fillingCoef = CGFloat((account.showingRemainder / account.showingBudgetAmount).doubleValue)
                
                return LinearGradient(
                    gradient: Gradient(colors: [.gray, .green]),
                    startPoint: .init(x: 0.5, y: 1 - fillingCoef),
                    endPoint: .init(x: 0.5, y: 1 - fillingCoef + 0.01)
                )
            default:
                return LinearGradient(
                    gradient: Gradient(colors: [.red]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        case .earnings:
            switch true {
            case account.showingBudgetAmount != 0 && account.showingRemainder <= account.showingBudgetAmount:
                
                let fillingCoef = CGFloat((account.showingRemainder / account.showingBudgetAmount).doubleValue)
                
                return LinearGradient(
                    gradient: Gradient(colors: [.gray, .blue]),
                    startPoint: .init(x: 0.5, y: 1 - fillingCoef),
                    endPoint: .init(x: 0.5, y: 1 - fillingCoef + 0.01)
                )
            default:
                return LinearGradient(
                    gradient: Gradient(colors: [.blue]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
    
    var body: some View {
        Rectangle()
            .fill(objectColor)
            .mask {
                ZStack {
                    if account.isParent && account.type != .balancing {
                        Circle()
                            .fill(.clear)
                            .strokeBorder(.black, lineWidth: 2)
                            .frame(width: 56)
                    }
                    Circle()
                        .frame(width: 50)
                }
            }
            .overlay{
                AsyncImage(url: URL.documentsDirectory.appending(path: account.icon.url)) { image in
                    image.image?
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30)
                }
            }
            .frame(height: 60)
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
