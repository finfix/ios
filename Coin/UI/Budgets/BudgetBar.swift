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
        account.remainder.doubleValue / account.budgetAmount.doubleValue
    }
    
    var partWidthFixed: CGFloat {
        return CGFloat(account.budgetFixedSum.doubleValue / account.budgetAmount.doubleValue) * width / CGFloat(account.budgetDaysOffset)
    }
    
    var partWidthLeft: CGFloat {
        return CGFloat(1 - account.budgetFixedSum.doubleValue / account.budgetAmount.doubleValue) * width / CGFloat(daysInMonth - Int(account.budgetDaysOffset))
    }
    
    var availableCoef: CGFloat {
        Double(today) / Double(daysInMonth)
    }
    
    var body: some View {
        // Прямоугольник
        ZStack(alignment: .leading) {
            // Бюджет
            HStack(spacing: 0) {
                ForEach(0 ..< Int(account.budgetDaysOffset), id: \.self) { index in
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
                      (fillingCoef > availableCoef && account.budgetGradualFilling) ? .yellow : .green)
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
    BudgetBar(account: Account())
}
