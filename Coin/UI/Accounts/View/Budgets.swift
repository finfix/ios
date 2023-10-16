//
//  Budgets.swift
//  Coin
//
//  Created by Илья on 16.10.2023.
//

import SwiftUI

struct Example: Identifiable {
    var id = UUID()
    var budget: Double
    var expense: Double
    var name: String
    var currencySymbol: String
}

struct BudgetsView: View {
    
    let example: [Example] = [
        Example(budget: 1753715, expense: 1625535, name: "Транспорт", currencySymbol: "₫"),
        Example(budget: 901911, expense: 0, name: "Развлечения", currencySymbol: "₫"),
        Example(budget: 6413588, expense: 3117854, name: "Еда", currencySymbol: "₫"),
    ]
    
    var body: some View {
        VStack {
            ForEach(example) { exampleItem in
                BudgetBar(
                    budget: exampleItem.budget,
                    expense: exampleItem.expense,
                    name: exampleItem.name,
                    currencySymbol: exampleItem.currencySymbol)
                .padding()
            }
        }
    }
}

struct BudgetBar: View {
    let budget: Double
    let expense: Double
    
    let name: String
    let currencySymbol: String
    
    let cornerRadius: CGFloat = 10
    let daysInMonths = 30
    
    let width: CGFloat = UIScreen.main.bounds.width * 0.8
    let height: CGFloat = 60
    let today = Calendar.current.component(.day, from: Date())

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
                        .fill(expense <= budget/Double(daysInMonths)*Double(today) ? Color.green : Color.red)
                        .frame(width: width*(expense/budget), height: height)
                    // Текущий день
                        Line()
                            .stroke(Color.gray, style: StrokeStyle(lineWidth: 2, dash: [2]))
                            .frame(width: 1, height: height)
                            .offset(x: width * (CGFloat(today) / CGFloat(daysInMonths)), y: 0)
                    VStack(alignment: .leading) {
                        Text(name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("Остаток: \(String(format: "%.0f", budget/Double(daysInMonths)*Double(today)-expense)) \(currencySymbol)")
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
