//
//  CreateTransaction.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import SwiftUI

struct CreateTransactionView: View {
    
    @Binding var isOpeningFrame: Bool
    @State private var d = false
    
    @State private var accountFromID = ""
    @State private var accountToID: String = ""
    @State private var amountFrom: String = ""
    @State private var amountTo: String = ""
    @State private var selectedType: Int = 0
    @State private var note = ""
    @State private var date = Date()
    
    let types = ["consumption", "income", "transfer"]
    
    var body: some View {
        VStack {
            Form {
                Section {
                    Toggle(isOn: $d) {
                        Text("Межвалютная транзакция")
                    }
                }
                
                Section {
                    TextField("Счет списания", text: $accountFromID)
                    TextField("Счет начисления", text: $accountToID)
                    if d {
                        TextField("Cумма списания", text: $amountFrom)
                        TextField("Сумма начисления", text: $amountTo)
                    } else {
                        TextField("Сумма", text: $amountFrom)
                    }
                    DatePicker(selection: $date, displayedComponents: .date) {
                        Text("Дата транзакции")
                    }
                    Picker(selection: $selectedType) {
                        ForEach(0..<types.count, id: \.self) { Text(self.types[$0]) }
                    } label: {
                        Text("Тип транзакции")
                    }
                    .pickerStyle(.segmented)
                    
                }
                Section {
                    ZStack(alignment: .topLeading) {
                        if note.isEmpty {
                            Text("Заметка")
                                .foregroundColor(.gray)
                                .padding()
                        }
                        TextEditor(text: $note)
                            .lineLimit(5)
                    }
                    
                }
                
            }
            Spacer()
            Button {
                let format = DateFormatter()
                format.dateFormat = "YYYY-MM-dd"
                
                TransactionAPI().CreateTransaction(req: CreateTransactionRequest(accountFromID: Int(accountFromID) ?? 0, accountToID: Int(accountToID) ?? 0, amountFrom: Double(amountFrom) ?? 0, amountTo: (d ? Double(amountTo) : Double(amountFrom)) ?? 0, dateTransaction: format.string(from: date), note: note, type: types[selectedType], isExecuted: true)) {
                    print("Создание транзакции прошло успешно")
                }
                isOpeningFrame = false
            } label: {
                Text("Сохранить")
            }
            .padding()
        }
    }
}

struct CreateTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        CreateTransactionView(isOpeningFrame: .constant(false))
    }
}

