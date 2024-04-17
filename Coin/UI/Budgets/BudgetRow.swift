//
//  Budget.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import SwiftUI

struct BudgetRow: View {
    
    var account: Account
    @State var isDetailsOpened = false
    
    let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())!.count
    let today = Calendar.current.component(.day, from: Date())

    var body: some View {
        Button {
            withAnimation {
                isDetailsOpened.toggle()
            }
        } label: {
            BudgetBar(account: account)
        }
        if isDetailsOpened {
            BudgetDetails(account: account)
        }
    }
}

#Preview {
    BudgetRow(account: Account())
        .environment(AlertManager(handle: {_ in }))
}
