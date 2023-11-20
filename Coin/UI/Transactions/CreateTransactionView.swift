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
    
    init(isOpeningFrame: Binding<Bool>, transactionType: TransactionType) {
        self._isOpeningFrame = isOpeningFrame
        self.transactionType = transactionType
    }
    
    var filteredAccounts: [Account] {
        modelData.accounts.filter {
            $0.visible && $0.childrenAccounts.count == 0
        }
    }
    
    var accountsFrom: [Account] {
        filteredAccounts.filter {
            switch transactionType {
            case .consumption:
                return $0.type != .expense && $0.type != .earnings && $0.accountGroupID == accountGroupFrom.id
            case .income:
                return $0.type == .earnings && $0.accountGroupID == accountGroupFrom.id
            case .transfer:
                return $0.type != .expense && $0.type != .earnings && $0.accountGroupID == accountGroupFrom.id
            default:
                return true
            }
        }
    }
    
    var accountsTo: [Account] {
        filteredAccounts.filter {
            switch transactionType {
            case .consumption:
                return $0.type == .expense && $0.accountGroupID == accountGroupTo.id
            case .income:
                return $0.type != .expense && $0.type != .earnings && $0.accountGroupID == accountGroupTo.id
            case .transfer:
                return $0.type != .expense && $0.type != .earnings && $0.id != accountFrom.id && $0.accountGroupID == accountGroupTo.id
            default:
                return true
            }
        }
    }
    
    var transactionType: TransactionType
    @State var accountGroupFrom = AccountGroup()
    @State var accountGroupTo = AccountGroup()
    @State var accountFrom = Account()
    @State var accountTo = Account()
    @State var amountFrom: String = ""
    @State var amountTo: String = ""
    @State var selectedType: Int = 0
    @State var note = ""
    @State var date = Date()
    
    var intercurrency: Bool {
        return accountFrom.currency != accountTo.currency
    }
    
    var body: some View {
        Form {
            Section {
                HStack(spacing: 0) {
                    Picker("", selection: $accountGroupFrom) {
                        ForEach (modelData.accountGroups) { accountGroup in
                            Text(accountGroup.name)
                                .tag(accountGroup)
                        }
                    }
                    Picker("", selection: $accountFrom) {
                        ForEach (accountsFrom) { account in
                            HStack {
                                Text(account.name)
                                Spacer()
                                Text(CurrencySymbols[account.currency]!)
                                    .foregroundColor(.secondary)
                            }
                            .tag(account)
                        }
                    }
                }
                
                HStack(spacing: 0) {
                    Picker("", selection: $accountGroupTo) {
                        ForEach (modelData.accountGroups) { accountGroup in
                            Text(accountGroup.name)
                                .tag(accountGroup)
                        }
                    }
                    Picker("", selection: $accountTo) {
                        ForEach (accountsTo) { account in
                            HStack {
                                Text(account.name)
                                Spacer()
                                Text(CurrencySymbols[account.currency]!)
                                    .foregroundColor(.secondary)
                            }
                            .tag(account)
                        }
                    }
                }
                
                TextField(intercurrency ? "Сумма списания" : "Сумма", text: $amountFrom)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                if intercurrency {
                    TextField("Сумма начисления", text: $amountTo)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                
                DatePicker(selection: $date, displayedComponents: .date) {
                    Text("Дата транзакции")
                }
            }
            #if os(iOS)
            .pickerStyle(.wheel)
            #endif
            Section {
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
                Button {
                    createTransaction()
                    isOpeningFrame = false
                } label: {
                    Text("Сохранить")
                }
                .padding()
            }
        }
        .onAppear {
            self.accountGroupFrom = modelData.accountGroups.first!
            self.accountGroupTo = modelData.accountGroups.first!
            if !accountsFrom.isEmpty {
                self.accountFrom = accountsFrom.first!
            }
            if !accountsTo.isEmpty {
                self.accountTo = accountsTo.first!
            }
        }
    }
    
    func createTransaction() {
        let format = DateFormatter()
        format.dateFormat = "YYYY-MM-dd"
        
        if !intercurrency {
            amountTo = amountFrom
        }
        
        Task {
            do {
                try await TransactionAPI().CreateTransaction(req: CreateTransactionReq(
                    accountFromID: accountFrom.id,
                    accountToID: accountTo.id,
                    amountFrom: Double(amountFrom.replacingOccurrences(of: ",", with: ".")) ?? 0,
                    amountTo: Double(amountTo.replacingOccurrences(of: ",", with: ".")) ?? 0,
                    dateTransaction: format.string(from: date),
                    note: note,
                    type: transactionType.rawValue,
                    isExecuted: true))
            } catch {
                debugLog(error)
            }
        }
    }
}

#Preview {
    CreateTransactionView(isOpeningFrame: .constant(true), transactionType: .transfer)
}

