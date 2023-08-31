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
    @State var transactionType: TransactionType
        
    var body: some View {
        VStack {
            Form {
                Section {
                    
                    Picker("Выберите счет списания", selection: $vm.accountFrom) {
                        ForEach (vm.accounts.filter {
                            switch transactionType {
                            case .consumption:
                                return $0.type != "expense" && $0.type != "earnings" && $0.visible
                            case .income:
                                return $0.type == "earnings" && $0.visible
                            case .transfer:
                                return $0.type != "expense" && $0.type != "earnings" && $0.visible
                            }
                            
                        }, id: \.self) {
                            Text($0.name).tag($0 as Account?)
                        }
                    }
                    
                    // Пикер счета получения
                    Picker("Выберите счет получения", selection: $vm.accountTo) {
                        ForEach (vm.accounts.filter {
                            switch transactionType {
                            case .consumption:
                                return $0.type == "expense" && $0.visible
                            case .income:
                                return $0.type != "expense" && $0.type != "earnings" && $0.visible
                            case .transfer:
                                return $0.type != "expense" && $0.type != "earnings" && $0.visible && $0.id != vm.accountFrom?.id
                            }
                        }, id: \.self) {
                            Text($0.name).tag($0 as Account?)
                        }
                    }
                    
                    if vm.intercurrency {
                        TextField("Cумма списания", text: $vm.amountFrom)
                        TextField("Сумма начисления", text: $vm.amountTo)
                    } else {
                        TextField("Сумма", text: $vm.amountFrom)
                            .keyboardType(.decimalPad)
                    }
                    DatePicker(selection: $vm.date, displayedComponents: .date) {
                        Text("Дата транзакции")
                    }                
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
                vm.transactionType = transactionType
                vm.createTransaction(appSettings, isOpeningFrame: $isOpeningFrame)
                isOpeningFrame = false
            } label: {
                Text("Сохранить")
            }
            .padding()
            .onAppear{ vm.getAccount() }
        }
    }
}

struct CreateTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        CreateTransactionView(isOpeningFrame: .constant(true), transactionType: .transfer)
            .environmentObject(AppSettings())
    }
}

