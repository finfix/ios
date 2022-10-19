//
//  UpdateTransactionView.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import SwiftUI

struct UpdateTransactionView: View {
    
    @Binding var isOpeningFrame: Bool
    @State private var d = false
    @State var t: Transaction
    
    var body: some View {
        VStack {
            Form {
                Section {
                    Toggle(isOn: $d) {
                        Text("Межвалютная транзакция")
                    }
                }
                
                Section {
                    // TextField("Счет списания", text: $t.accountFromID)
                    // TextField("Счет начисления", text: String($t.accountToID))
                    // if d {
                    //     TextField("Cумма списания", text: String($t.amountFrom))
                    //     TextField("Сумма начисления", text: String($t.amountTo))
                    // } else {
                    //     TextField("Сумма", text: String($t.amountFrom))
                    // }
                    // DatePicker(selection: $t.date, displayedComponents: .date) {
                    //     Text("Дата транзакции")
                    // }
                    // .pickerStyle(.segmented)
                    
                }
                // Section {
                //     ZStack(alignment: .topLeading) {
                //         if let note = t.note, note.isEmpty {
                //             Text("Заметка")
                //                 .foregroundColor(.gray)
                //                 .padding()
                //         }
                //         TextEditor(text: $t.note)
                //             .lineLimit(5)
                //     }
                //
            }
            Spacer()
            Button {
                TransactionAPI().UpdateTransaction(req: UpdateTransactionRequest(accountFromID: Int(t.accountFromID) , accountToID: Int(t.accountToID) , amountFrom: Double(t.amountFrom) , amountTo: Double(t.amountTo) , dateTransaction: t.dateTransaction, note: t.note ?? "", id: t.id, isExecuted: t.isExecuted)) {
                }
                isOpeningFrame = false
            } label: {
                Text("Сохранить")
            }
            .padding()
        }
    }
}

struct UpdateTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateTransactionView(isOpeningFrame: .constant(true), t: Transaction(accountFromID: 1, accountToID: 100, accounting: true, amountFrom: 100, amountTo: 100, dateTransaction: "2022-10-17", id: 1700, isExecuted: true, typeSignatura: "consuption"))
    }
}
