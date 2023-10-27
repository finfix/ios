//
//  UpdateTransaction.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI

struct UpdateTransaction: View {
    
    @Binding var isUpdateOpen: Bool
    
    var id: UInt32
    @State var amountFrom: String
    @State var amountTo: String
    @State var note: String
    
    init(isUpdateOpen: Binding<Bool>, transaction: Transaction) {
        self._isUpdateOpen = isUpdateOpen
        self.id = transaction.id
        self.amountFrom = String(transaction.amountFrom)
        self.amountTo = String(transaction.amountTo)
        self.note = transaction.note
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Сумма списания", text: $amountFrom)
                    .keyboardType(.decimalPad)
                TextField("Сумма зачисления", text: $amountTo)
                    .keyboardType(.decimalPad)
                ZStack(alignment: .topLeading) {
                    if note.isEmpty {
                        Text("Заметка")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    TextEditor(text: $note)
                        .lineLimit(5)
                }
            }
            Section {
                Button("Сохранить") {
                    isUpdateOpen = false
                    updateTransaction()
                }
            }
        }
    }
    
    func updateTransaction() {
        
        var req = UpdateTransactionReq(id: id)
        req.note = note
        req.amountFrom = Double(self.amountFrom.replacingOccurrences(of: ",", with: "."))
        req.amountTo = Double(self.amountTo.replacingOccurrences(of: ",", with: "."))
        
        TransactionAPI().UpdateTransaction(req: req) { error in
            if let err = error {
                showErrorAlert(error: err)
            }
        }
    }
}

#Preview {
    UpdateTransaction(isUpdateOpen: .constant(true), transaction: Transaction(
        accountFromID: 1,
        accountToID: 2,
        accounting: true,
        amountFrom: 30,
        amountTo: 50,
        dateTransaction: Date(),
        id: 1,
        isExecuted: true,
        note: "Заметка",
        type: .transfer))
}
