//
//  Header.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct Header: View {
    
    @Environment(ModelData.self) var modelData
    
    var body: some View {
        HStack(spacing: 35) {
            VStack {
                Text("Расход")
                Text("\(modelData.quickStatistic.totalExpense, specifier: "%.0f") ₽")
            }
            RoundedRectangle(cornerRadius: 0)
                .frame(width: 1, height: 44)
            VStack {
                Text("Баланс")
                Text("\(modelData.quickStatistic.totalRemainder, specifier: "%.0f") ₽")
            }
            RoundedRectangle(cornerRadius: 0)
                .frame(width: 1, height: 44)
            VStack {
                Text("Бюджет")
                Text("\(modelData.quickStatistic.leftToSpend, specifier: "%.0f") ₽")
                Text("\(modelData.quickStatistic.totalBudget, specifier: "%.0f") ₽")
                    .font(.footnote)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(Color("Gray"))
    }
}

#Preview {
    Header()
}
