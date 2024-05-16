//
//  BudgetBar.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct BudgetBar: View {
    
    var account: Account
    var today: Int
    
    let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())!.count
    let width: CGFloat = UIScreen.main.bounds.width * 0.9
    let height: CGFloat = 60
    
    var fillingCoef: CGFloat {
        account.showingRemainder.doubleValue / account.showingBudgetAmount.doubleValue
    }
    
    var partWidthFixed: CGFloat {
        let daysOffset = account.budgetDaysOffset == 0 ? 1 : account.budgetDaysOffset
        return CGFloat(account.budgetFixedSum.doubleValue / account.showingBudgetAmount.doubleValue) * width / CGFloat(daysOffset)
    }
    
    var partWidthLeft: CGFloat {
        return CGFloat(1 - account.budgetFixedSum.doubleValue / account.showingBudgetAmount.doubleValue) * width / CGFloat(daysInMonth - Int(account.budgetDaysOffset))
    }
    
    var offsetForLine: CGFloat {
        if account.budgetFixedSum != 0 {
            if account.budgetDaysOffset != 0, today <= account.budgetDaysOffset {
                return partWidthFixed * CGFloat(today)
            }
            return partWidthFixed * CGFloat(account.budgetDaysOffset) + partWidthLeft * CGFloat(today-Int(account.budgetDaysOffset))
        }
        return partWidthLeft * CGFloat(today)
    }
    
    var body: some View {
        // Прямоугольник
        ZStack(alignment: .leading) {
            // Бюджет
            HStack(spacing: 0) {
                ForEach(0 ..< Int(account.budgetDaysOffset == 0 ? 1 : account.budgetDaysOffset), id: \.self) { index in
                    Rectangle()
                        .fill(index % 2 == 0 ? .white : Color("LightGray"))
                        .frame(width: partWidthFixed, height: height)
                }
                ForEach(Int(account.budgetDaysOffset) ..< daysInMonth, id: \.self) { index in
                    Rectangle()
                        .fill(index % 2 == 0 ? .white : Color("LightGray"))
                        .frame(width: partWidthLeft, height: height)
                }
            }
            // Уже потрачено
            Rectangle()
            // Если бюджет превышен - красный
                .fill(fillingCoef > 1 ? .red :
                        // Если бюджет на текущий день превышен и счет с постепенным заполнением бюджета - желтый
                      (fillingCoef * width > offsetForLine && account.budgetGradualFilling) ? .yellow : .green)
                .frame(width: fillingCoef <= 1 ? width * fillingCoef : width, height: height)
                .opacity(0.5)
            // Текущий день
            Line()
                .stroke(Color.gray, style: StrokeStyle(lineWidth: 2, dash: [2]))
                .frame(width: 1, height: height)
                .offset(x: offsetForLine, y: 0)
            // Название счета
            Text(account.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.black)
                .padding(.leading)
        }
        .frame(width: width)
        .cornerRadius(10)
    }
}

#Preview {
    BudgetBar(account:
                Account(
                    showingRemainder: 4420000,
                    showingBudgetAmount: 7200000,
                    budgetFixedSum: 4420000,
                    budgetDaysOffset: 16
                ),
              today: 17
    )
        .environment(AlertManager(handle: {_ in }))
}
