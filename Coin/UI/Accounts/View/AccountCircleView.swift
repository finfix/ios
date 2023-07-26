//
//  AccountCircleView.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI

struct AccountCircleView: View {
    
    @StateObject var vm = AccountViewModel()
    @EnvironmentObject var appSettings: AppSettings
    
    let rows = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // Расход на текущий день
        var todayExpense: Int {
            var sum = 0.0
            let expenses = vm.accountsGrouped.filter { $0.type == "expense" && $0.accounting }
            expenses.forEach { expense in
                sum += expense.remainder
            }
            return Int(sum)
        }
        
        // Баланс
        var balance: Int {
            var sum = 0.0
            let regulars = vm.accountsGrouped.filter { $0.type == "regular" && $0.accounting }
            regulars.forEach { regular in
                sum += regular.remainder
            }
            return Int(sum)
        }
        
        // Остаток до конца месяца
        var mountRemainder: Int {
            var sum = 0.0
            let expenses = vm.accountsGrouped.filter { $0.type == "expense" && $0.accounting }
            expenses.forEach { expense in
                sum += expense.budget
            }
            return Int(sum) - todayExpense
        }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 35) {
                        VStack {
                            Text("Расход")
                            Text("\(todayExpense)")
                        }
                        RoundedRectangle(cornerRadius: 0)
                            .frame(width: 1, height: 44)
                        VStack {
                            Text("Баланс")
                            Text("\(balance)")
                        }
                        RoundedRectangle(cornerRadius: 0)
                            .frame(width: 1, height: 44)
                        VStack {
                            Text("Бюджет")
                            Text("\(mountRemainder)")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color("Gray"))
            // SelectAccountGroup()
            ScrollView(.horizontal) {
                HStack {
                    CirclesArrayView(accounts: $vm.accountsGrouped.filterB { ($0.type == "earnings") && $0.visible })
                }
            }.frame(maxHeight: 100)
            
            Divider()
            
            ScrollView(.horizontal) {
                HStack {
                    CirclesArrayView(accounts: $vm.accountsGrouped.filterB { ($0.type != "earnings") && ($0.type != "expense") && $0.visible })
                }
            }.frame(maxHeight: 100)
            
            Divider()
            
            ScrollView(.horizontal) {
                    LazyHGrid(rows: rows) {
                        CirclesArrayView(accounts: $vm.accountsGrouped.filterB {($0.type == "expense") && $0.visible })
                    }
            }
            .frame(maxHeight: .infinity)
            Spacer()
        }
        .onAppear { vm.getAccountGrouped(appSettings) }
    }
}

struct CirclesArrayView: View {
    
    @Binding var accounts: [Account]
    
    var body: some View {
        ForEach(accounts, id: \.id) { account in
            VStack {
                Text(account.name)
                    .lineLimit(1)
                    .font(.footnote)
                
                // Если бюджет нулевой, показываем серый круг
                if account.budget == 0 {
                    Circle()
                        .frame(width: 30)
                        .foregroundColor(.gray)
                } else {
                    
                    // Если не нулевой и расход меньше или равен бюджету, зеленый
                    if account.budget >= account.remainder {
                        Circle()
                            .frame(width: 30)
                            .foregroundColor(.green)
                    } else {
                        
                        // Если расход больше бюджета, красный
                        Circle()
                            .frame(width: 30)
                            .foregroundColor(.red)
                    }
                }
                
                // Остаток
                Text(String(format: "%.2f", account.remainder))
                    .lineLimit(1)
                    .font(.footnote)
                
                // Бюджет
                if account.budget != 0 {
                    Text(String(format: "%.0f", account.budget))
                        .lineLimit(1)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 70)
        }
        .frame(width: 90)
    }
}

struct AccountCircleView_Previews: PreviewProvider {
    static var previews: some View {
        // CircleView(name: "Название", remainder: 9324)
        AccountCircleView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 7"))
    }
}

extension Binding where Value == [Account] {//where Account is your type
    func filterB(_ condition: @escaping (Account) -> Bool) -> Binding<Value> {//where String is your type
        return Binding {
            return wrappedValue.filter({condition($0)})
        } set: { newValue in
            wrappedValue = newValue
        }
    }
}

