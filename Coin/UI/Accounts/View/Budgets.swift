//
//  Budgets.swift
//  Coin
//
//  Created by Илья on 16.10.2023.
//

import SwiftUI

struct BudgetsView: View {
    
    var accounts: [Account] = [
            Account(accountGroupID: 1, accounting: true, budget: 800, currency: "RUB", iconID: 5, id: 1, name: "Еда вне дома", remainder: 500, type: "", visible: true, currencySymbol: "₽"),
            Account(accountGroupID: 1, accounting: true, budget: 8000, currency: "RUB", iconID: 5, id: 2, name: "Трнспорт", remainder: 500, type: "", visible: true, currencySymbol: "$"),
            Account(accountGroupID: 1, accounting: true, budget: 800, currency: "RUB", iconID: 5, id: 3, name: "Развлечения", remainder: 5000, type: "", visible: true, currencySymbol: "₽"),
        ]
    
    var body: some View {
        VStack {
            ForEach(accounts) { account in
                BudgetBar(account: account)
            }
        }
    }
}

struct BudgetBar: View {
    var account: Account
    
    let cornerRadius: CGFloat = 10
    let daysInMonths = 30
    
    let width: CGFloat = UIScreen.main.bounds.width * 0.8
    let height: CGFloat = 60
    let today = Calendar.current.component(.day, from: Date())
    
    var fillingCoef: CGFloat {
        return account.remainder / account.budget
    }
    
    var avaliablleToExpense: Double {
        return account.budget/Double(daysInMonths)*Double(today)
    }

    var body: some View {
            ZStack(alignment: .trailing) {
                // Прямоугольник
                ZStack(alignment: .leading) {
                    // 30 частей - бюджет
                    HStack(spacing: 0) {
                        ForEach(0..<daysInMonths, id: \.self) { index in
                            Rectangle()
                                .fill(index % 2 == 0 ? .white : Color("LightGray"))
                                .frame(width: width/CGFloat(daysInMonths), height: height)
                        }
                    }
                    // Текущий расход
                    Rectangle()
                        .fill(account.remainder <= avaliablleToExpense ? Color.green : Color.red)
                        .frame(width: fillingCoef < 1 ? width * fillingCoef : width, height: height)
                    // Текущий день
                        Line()
                            .stroke(Color.gray, style: StrokeStyle(lineWidth: 2, dash: [2]))
                            .frame(width: 1, height: height)
                            .offset(x: width * (CGFloat(today) / CGFloat(daysInMonths)), y: 0)
                    VStack(alignment: .leading) {
                        Text(account.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("Остаток: \(String(format: "%.0f", avaliablleToExpense-account.remainder)) \(account.currencySymbol)")
                            .font(.footnote)
                    }
                    .padding(.leading)
                }
                .cornerRadius(cornerRadius)
                
//                VStack(alignment: .trailing) {
//                    Text("\(String(format: "%.0f", budget)) \(currencySymbol)")
//                        .foregroundColor(Color.primary)
//                    Text("\(String(format: "%.0f", expense)) \(currencySymbol)")
//                        .foregroundColor(Color.gray)
//                }
//                .padding(.trailing)
        }
    }
}

#Preview {
    BudgetsView()
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        return path
    }
}
