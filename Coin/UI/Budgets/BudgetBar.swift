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
        account.remainder / account.budget
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
                .fill(fillingCoef <= availableCoef ? Color.green : Color.red)
                .frame(width: fillingCoef < 1 ? width * fillingCoef : width, height: height)
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
    BudgetBar(account: Account(id: 1, accountGroupID: 1, accounting: true, budget: 900, currency: "rub", iconID: 2, name: "Example", remainder: 600, type: .expense, visible: true))
}
