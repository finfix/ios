//
//  CreateTransaction.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import SwiftUI

struct CreateTransactionView: View {
    
    @Binding var isOpeningFrame: Bool
    @Environment(ModelData.self) var modelData
    @Environment(AppSettings.self) var appSettings
    
    var transactionType: TransactionType
    @State var accountFrom: Account?
    @State var accountTo: Account?
    @State var amountFrom: String = ""
    @State var amountTo: String = ""
    @State var selectedType: Int = 0
    @State var note = ""
    @State var date = Date()
    
    var intercurrency: Bool {
        return accountFrom?.currency != accountTo?.currency
    }
    
    var body: some View {
        VStack {
            Form {
//                Section {
                    Picker("Выберите счет списания", selection: $accountFrom) {
                        ForEach (modelData.accounts.filter {
                            switch transactionType {
                            case .consumption:
                                return $0.type != .expense && $0.type != .earnings && $0.visible
                            case .income:
                                return $0.type == .earnings && $0.visible
                            case .transfer:
                                return $0.type != .expense && $0.type != .earnings && $0.visible
                            default:
                                return true
                            }
                            
                        }, id: \.self) {
                            Text($0.name).tag($0 as Account?)
                        }
                    }
                    
                    // Пикер счета получения
                    Picker("Выберите счет получения", selection: $accountTo) {
                        ForEach (modelData.accounts.filter {
                            switch transactionType {
                            case .consumption:
                                return $0.type == .expense && $0.visible
                            case .income:
                                return $0.type != .expense && $0.type != .earnings && $0.visible
                            case .transfer:
                                return $0.type != .expense && $0.type != .earnings && $0.visible && $0.id != accountFrom?.id
                            default:
                                return true
                            }
                        }, id: \.self) {
                            Text($0.name).tag($0 as Account?)
                        }
                    }
                    
                    TextField(intercurrency ? "Сумма списания" : "Сумма", text: $amountFrom)
                        .keyboardType(.decimalPad)
                    if intercurrency {
                        TextField("Сумма начисления", text: $amountTo)
                            .keyboardType(.decimalPad)
                    }
                    
                    DatePicker(selection: $date, displayedComponents: .date) {
                        Text("Дата транзакции")
                    }
//                }
//                Section {
                    ZStack(alignment: .topLeading) {
                        if note.isEmpty {
                            Text("Заметка")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                        TextEditor(text: $note)
                            .lineLimit(5)
                    }
//                }
            }
            Spacer()
            Button {
                createTransaction()
                isOpeningFrame = false
            } label: {
                Text("Сохранить")
            }
            .padding()
            .onAppear(perform: modelData.getAccounts)
        }
    }
    
    func createTransaction() {
        let format = DateFormatter()
        format.dateFormat = "YYYY-MM-dd"
        
        if !intercurrency {
            amountTo = amountFrom
        }
        
        TransactionAPI().CreateTransaction(req: CreateTransactionRequest(
            accountFromID: accountFrom!.id,
            accountToID: accountTo!.id,
            amountFrom: Double(amountFrom.replacingOccurrences(of: ",", with: ".")) ?? 0,
            amountTo: Double(amountTo.replacingOccurrences(of: ",", with: ".")) ?? 0,
            dateTransaction: format.string(from: date),
            note: note,
            type: transactionType.rawValue,
            isExecuted: true)) { error in
                if let err = error {
                    appSettings.showErrorAlert(error: err)
                }
            }
    }
}

#Preview {
    CreateTransactionView(isOpeningFrame: .constant(true), transactionType: .transfer)
}

