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
            let expenses = vm.accounts.filter { $0.typeSignatura == "expense" && $0.accounting }
            expenses.forEach { expense in
                sum += expense.remainder
            }
            return Int(sum)
        }
        
        // Баланс
        var balance: Int {
            var sum = 0.0
            let regulars = vm.accounts.filter { $0.typeSignatura == "regular" && $0.accounting }
            regulars.forEach { regular in
                sum += regular.remainder
            }
            return Int(sum)
        }
        
        // Остаток до конца месяца
        var mountRemainder: Int {
            var sum = 0.0
            let expenses = vm.accounts.filter { $0.typeSignatura == "expense" && $0.accounting }
            expenses.forEach { expense in
                sum += expense.budget ?? 0
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
                    CirclesArrayView(accounts: $vm.accounts.filterB { ($0.typeSignatura == "earnings") && $0.visible })
                }
            }.frame(maxHeight: 100)
            
            Divider()
            
            ScrollView(.horizontal) {
                HStack {
                    CirclesArrayView(accounts: $vm.accounts.filterB { ($0.typeSignatura != "earnings") && ($0.typeSignatura != "expense") && $0.visible })
                }
            }.frame(maxHeight: 100)
            
            Divider()
            
            ScrollView(.horizontal) {
                    LazyHGrid(rows: rows) {
                        CirclesArrayView(accounts: $vm.accounts.filterB {($0.typeSignatura == "expense") && $0.visible })
                    }
            }
            .frame(maxHeight: .infinity)
            Spacer()
        }
        .onAppear { vm.getAccount(appSettings) }
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
                
                if account.budget == nil {
                    Circle()
                        .frame(width: 30)
                        .foregroundColor(.gray)
                }
                if let budget = account.budget {
                    if budget > account.remainder {
                        Circle()
                            .frame(width: 30)
                            .foregroundColor(.green)
                    } else {
                        Circle()
                            .frame(width: 30)
                            .foregroundColor(.red)
                    }
                }
                
                Text(String(format: "%.2f", account.remainder))
                    .lineLimit(1)
                    .font(.footnote)
                
                if let budget = account.budget {
                    Text(String(format: "%.2f", budget))
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

