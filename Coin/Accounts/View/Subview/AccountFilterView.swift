//
//  AccountFilterView.swift
//  Coin
//
//  Created by Илья on 14.10.2022.
//

import SwiftUI

struct AccountFilterView: View {
    
    @ObservedObject var vm = AccountViewModel()
    
    @Binding var visible: Bool
    @Binding var accounting: Bool
    @Binding var accountType: Int
    @Binding var withoutZeroRemainder: Bool
    
    var body: some View {
        VStack {
            Toggle("Видимые", isOn: $visible)
            Toggle("Учитываемые", isOn: $accounting)
            Toggle("Ненулевые", isOn: $withoutZeroRemainder)
            Picker(selection: $accountType) {
                ForEach(0..<vm.types.count, id: \.self) {
                    Text(vm.types[$0])
                }
            } label: {
                Text("Тип счета")
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .navigationTitle("Фильтры")
    }
}

struct AccountFilterView_Previews: PreviewProvider {
    @StateObject var vm = AccountViewModel()
    
    static var previews: some View {
        AccountFilterView(visible: .constant(true), accounting: .constant(true), accountType: .constant(0), withoutZeroRemainder: .constant(false))
        
    }
}
