//
//  Header.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI

struct Header: View {
    
    @StateObject var vm = AccountViewModel()
    
    var body: some View {
        HStack(spacing: 35) {
            VStack {
                Text("Расход")
                // Text("\(vm.todayExpense)")
            }
            RoundedRectangle(cornerRadius: 0)
                .frame(width: 1, height: 44)
            VStack {
                Text("Баланс")
                // Text("\(vm.balance)")
            }
            RoundedRectangle(cornerRadius: 0)
                .frame(width: 1, height: 44)
            VStack {
                Text("Бюджет")
                // Text("\(vm.mountRemainder)")
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(Color("Gray"))
    }
}

struct Header_Previews: PreviewProvider {
    static var previews: some View {
        Header()
    }
}
