//
//  Header.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct Header: View {
    
    @Environment(ModelData.self) var modelData
    
    let height: CGFloat = 40
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Text("Расход")
                    .bold()
                Text("\(modelData.quickStatistic.totalExpense, specifier: "%.0f") ₽")
            }
            Spacer()
            VStack {
                Text("Баланс")
                    .bold()
                Text("\(modelData.quickStatistic.totalRemainder, specifier: "%.0f") ₽")
            }
            Spacer()
            VStack {
                Text("Бюджет")
                    .bold()
                Text("\(modelData.quickStatistic.leftToSpend, specifier: "%.0f") ₽")
//                Text("\(modelData.quickStatistic.totalBudget, specifier: "%.0f") ₽")
            }
            Spacer()
        }
        .font(.caption2)
        .frame(maxWidth: .infinity)
        .frame(height: height)
//        .background(Color("StrongGray"))
    }
}

#Preview {
    Group {
        Header()
        Spacer()
    }
    .environment(ModelData())
}
