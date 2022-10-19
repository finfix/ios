//
//  AccountCircleView.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI

struct AccountCircleView: View {
    
    @StateObject var vm = AccountViewModel()
    
    let rows = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 10) {
            Header()
            // SelectAccountGroup()
            ScrollView(.horizontal, showsIndicators: true) {
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
        .onAppear(perform: vm.getAccount)
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
                
                Circle()
                    .frame(width: 50)
                    .foregroundColor(Color("StrongGray"))
                
                Text(String(format: "%.2f", account.remainder))
                    .lineLimit(1)
                    .font(.footnote)
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
