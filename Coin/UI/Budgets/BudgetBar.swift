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
    let today = Calendar.current.component(.day, from: Date())
    let paddingCoef = 0.1
    
    var fillingCoef: CGFloat {
        account.remainder.doubleValue / account.budget.doubleValue
    }
    
    var availableCoef: CGFloat {
        Double(today) / Double(daysInMonth)
    }
    
    var body: some View {
        GeometryReader { geometry in
            
            let width = geometry.size.width * (1 - paddingCoef)
            let height = geometry.size.height
            
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
            .offset(x: width*paddingCoef/2)
        }
    }
}

#Preview {
    VStack {
        BudgetBar(account: Account(budget: 100, name: "Незаполненный бюджет", remainder: 1, gradualBudgetFilling: true))
            .frame(height: 60)
        BudgetBar(account: Account(budget: 100, name: "Полностью заполненный бюджет постепенная", remainder: 100, gradualBudgetFilling: true))
            .frame(height: 60)
        BudgetBar(account: Account(budget: 100, name: "Полностью заполненный бюджет не постепенная", remainder: 100, gradualBudgetFilling: false))
            .frame(height: 60)
        BudgetBar(account: Account(budget: 100, name: "Превышенный бюджет", remainder: 200, gradualBudgetFilling: false))
            .frame(height: 60)
    }
}
