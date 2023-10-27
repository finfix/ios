//
//  Header.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct Header: View {
    
    @Environment(ModelData.self) var modelData
    
    var statistic: QuickStatistic {
        modelData.quickStatistic[modelData.selectedAccountsGroupID] ?? QuickStatistic()
    }
    
    var formatter = CurrencyFormatter(maximumFractionDigits: 0)
    
    let height: CGFloat = 40
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Text("Расход")
                    .bold()
                Text(formatter.string(number: statistic.totalExpense, currency: statistic.currency))
                Spacer()
            }
            Spacer()
            VStack {
                Text("Баланс")
                    .bold()
                Text(formatter.string(number: statistic.totalRemainder, currency: statistic.currency))
                Spacer()
            }
            Spacer()
            VStack {
                Text("Бюджет")
                    .bold()
                VStack(alignment: .trailing) {
                    Text(formatter.string(number: statistic.totalBudget, currency: statistic.currency))
                    Text(formatter.string(number: statistic.totalBudget - statistic.totalExpense, currency: statistic.currency))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            Spacer()
        }
        .font(.caption2)
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }
}

#Preview {
    Group {
        Header()
        Spacer()
    }
    .environment(ModelData())
}
