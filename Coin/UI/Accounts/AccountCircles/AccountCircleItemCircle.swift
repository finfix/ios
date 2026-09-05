//
//  AccountCircle.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

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

                // Если бюджет со постепенным заполнением и уже потрачено больше, чем
                // полагается на сегодняшний день — заполняем не зеленым, а желтым
                // (та же логика, что и на странице бюджетов, см. BudgetBar).
                let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())!.count
                let today = Calendar.current.component(.day, from: Date())
                let isOverTodaysBudget = account.budgetGradualFilling
                    && fillingCoef > account.expectedSpentFraction(today: today, daysInMonth: daysInMonth)

                return LinearGradient(
                    gradient: Gradient(colors: [.gray, isOverTodaysBudget ? .yellow : .green]),
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
                            .frame(height: 60)
                        Circle()
                            .frame(height: 54)
                    } else {
                        Circle()
                            .frame(height: 60)
                    }
                }
            }
            .overlay {
                CachedIconImage(fileName: account.icon.url)
                    .frame(width: 30)
            }
            .frame(height: 60)
    }
}
