//
//  OrderView.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI

struct AccountView: View {
    
    /// Добавляем Network в качестве EnvironmentObject
    @StateObject var vm = AccountViewModel()
    @State var showFilters = false
    
    var body: some View {
        NavigationView {
            VStack {
                List(vm.accountsFiltered, id: \.id) { account in
                    HStack {
                        Text(account.name)
                        
                        Spacer()
                        
                        VStack {
                            if account.remainder > account.budget ?? 0 {
                                Text(String(format: "%.2f", account.remainder))
                                    .foregroundColor(.red)
                            } else if account.remainder > Double(vm.getTodayRemainder(Int(account.budget ?? 0))) {
                                Text(String(format: "%.2f", account.remainder))
                                    .foregroundColor(.yellow)
                            } else if account.remainder < account.budget ?? 0 {
                                Text(String(format: "%.2f", account.remainder))
                            }
                            if let budget = account.budget {
                                Text("Бюджет: \(Int(budget))")
                                    .font(.footnote)
                            }
                        }
                    }
                }
                .onAppear {
                    vm.getAccount()
                }
                .navigationBarTitle(Text("Счета"))
                .navigationBarItems(trailing: NavigationLink {
                    AccountFilterView(visible: self.$vm.visible, accounting: self.$vm.accounting, accountType: self.$vm.accountType, withoutZeroRemainder: self.$vm.withoutZeroRemainder)
                } label: {
                    Text("Фильтры")
                }
                )
                Text("Сумма: \(vm.sum)₽")
                Text("Бюджет на месяц: \(vm.sumBudget)₽")
                Text("Остаток на месяц: \(vm.monthRemainder)₽")
                Text("Рекомендованный остаток: \(vm.todayRemainder)₽")
            }
        }
    }
}


struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}
