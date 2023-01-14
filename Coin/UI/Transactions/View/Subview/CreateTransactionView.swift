//
//  CreateTransaction.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import SwiftUI

struct CreateTransactionView: View {
    
    @EnvironmentObject var appSettings: AppSettings
    @StateObject var vm = TransactionViewModel()
    
    @Binding var isOpeningFrame: Bool
    @State private var d = false
    
    var body: some View {
        VStack {
            Form {
                Section {
                    Toggle(isOn: $d) {
                        Text("Межвалютная транзакция")
                    }
                }
                
                Section {
                    
                    // Пикер счета списания
                    Picker(selection: $vm.accountFromID) {
                        ForEach (vm.accounts.filter { $0.visible }) { account in
                            Text(account.name).tag(account.id)
                        }
                    } label: {
                        Text("Выберите счет списания")
                    }
                    
                    // Пикер счета получения
                    Picker(selection: $vm.accountToID) {
                        ForEach (vm.accounts.filter { $0.visible }) { account in
                            Text(account.name).tag(account.id)
                        }
                    } label: {
                        Text("Выберите счет списания")
                    }
                    
                    
                    if d {
                        TextField("Cумма списания", text: $vm.amountFrom)
                        TextField("Сумма начисления", text: $vm.amountTo)
                    } else {
                        TextField("Сумма", text: $vm.amountFrom)
                    }
                    DatePicker(selection: $vm.date, displayedComponents: .date) {
                        Text("Дата транзакции")
                    }
                    Picker(selection: $vm.selectedType) {
                        ForEach(0..<$vm.types.count, id: \.self) { Text(self.vm.types[$0]) }
                    } label: {
                        Text("Тип транзакции")
                    }
                    .pickerStyle(.segmented)
                
                }
                Section {
                    ZStack(alignment: .topLeading) {
                        if vm.note.isEmpty {
                            Text("Заметка")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                        TextEditor(text: $vm.note)
                            .lineLimit(5)
                    }
                }
            }
            Spacer()
            Button {
                vm.createTransaction(appSettings, isOpeningFrame: $isOpeningFrame)
                isOpeningFrame = false
            } label: {
                Text("Сохранить")
            }
            .padding()
            .onAppear { vm.getAccount(appSettings) }
        }
    }
}

struct CreateTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        CreateTransactionView(isOpeningFrame: .constant(true))
    }
}

