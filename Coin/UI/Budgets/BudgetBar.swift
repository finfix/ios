//
//  BudgetBar.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct BudgetBar: View {
    
    var account: Account
    
    let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())!.count
    let width: CGFloat = UIScreen.main.bounds.width * 0.9
    let height: CGFloat = 60
    let today = Calendar.current.component(.day, from: Date())
    
    var fillingCoef: CGFloat {
        account.remainder.doubleValue / account.budget.doubleValue
    }
    
    var availableCoef: CGFloat {
        Double(today) / Double(daysInMonth)
    }
    
    var body: some View {
        // Прямоугольник
        ZStack(alignment: .leading) {
            // Бюджет
            HStack(spacing: 0) {
                ForEach(0..<daysInMonth, id: \.self) { index in
                    Rectangle()
                        .fill(index % 2 == 0 ? .white : Color("LightGray"))
                        .frame(width: width / CGFloat(daysInMonth), height: height)
                }
            }
            // Уже потрачено
            Rectangle()
            // Если бюджет превышен - красный
                .fill(fillingCoef > 1 ? .red :
                        // Если бюджет на текущий день превышен и счет с постепенным заполнением бюджета - желтый
                        (fillingCoef > availableCoef && account.gradualBudgetFilling) ? .yellow : .green)
                .frame(width: fillingCoef <= 1 ? width * fillingCoef : width, height: height)
                .opacity(0.5)
            // Текущий день
            Line()
                .stroke(Color.gray, style: StrokeStyle(lineWidth: 2, dash: [2]))
                .frame(width: 1, height: height)
                .offset(x: width * availableCoef, y: 0)
            // Название счета
            Text(account.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.black)
                .padding(.leading)
        }
        .cornerRadius(10)
    }
}

#Preview {
    Group {
        BudgetBar(account: Account(budget: 100, name: "Незаполненный бюджет", remainder: 1, gradualBudgetFilling: true))
        BudgetBar(account: Account(budget: 100, name: "Полностью заполненный бюджет постепенная", remainder: 100, gradualBudgetFilling: true))
        BudgetBar(account: Account(budget: 100, name: "Полностью заполненный бюджет не постепенная", remainder: 100, gradualBudgetFilling: false))
        BudgetBar(account: Account(budget: 100, name: "Превышенный бюджет", remainder: 200, gradualBudgetFilling: false))
    }
}
