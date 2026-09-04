//
//  SelectAccountForTransfer.swift
//  Coin
//

import SwiftUI
import Factory

@Observable
class SelectAccountForTransferViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service

    let transfer: PendingLinkedTransfer
    var accounts: [Account] = []
    var myBridgeAccount: Account?
    var sourceTransaction: Transaction?

    init(transfer: PendingLinkedTransfer) {
        self.transfer = transfer
    }

    func load() async throws {
        guard let myBridgeAccount = try await service.getAccounts(ids: [transfer.targetAccountID]).first else {
            throw ErrorModel(humanText: "Не нашли свой счёт-мост")
        }
        self.myBridgeAccount = myBridgeAccount
        sourceTransaction = try await service.getTransactions(ids: [transfer.sourceTransactionID]).first
        accounts = try await service.getAccounts(accountGroups: [myBridgeAccount.accountGroup], visible: true)
            .filter { $0.id != myBridgeAccount.id }
    }

    /// Направление на моей стороне зеркалит направление у инициатора: если деньги ПРИШЛИ в
    /// счёт-мост там (он был accountTo), то у меня они продолжают путь ИЗ моста (мост — accountFrom),
    /// и наоборот.
    private var bridgeIsSource: Bool {
        sourceTransaction?.accountTo.id == transfer.sourceAccountID
    }

    var prefillAmount: Decimal {
        sourceTransaction?.amountFrom ?? 0
    }

    /// nil — комбинация счетов не поддерживается мостом (см. EditAccount: только
    /// regular↔regular, expense↔earnings).
    func transactionType(tappedAccount: Account) -> (TransactionType, accountFrom: Account, accountTo: Account)? {
        guard let myBridgeAccount else { return nil }
        let accountFrom = bridgeIsSource ? myBridgeAccount : tappedAccount
        let accountTo = bridgeIsSource ? tappedAccount : myBridgeAccount

        switch true {
        case accountFrom.type == .earnings && accountTo.type == .regular: return (.income, accountFrom, accountTo)
        case accountFrom.type == .regular && accountTo.type == .regular: return (.transfer, accountFrom, accountTo)
        case accountFrom.type == .regular && accountTo.type == .expense: return (.consumption, accountFrom, accountTo)
        default: return nil
        }
    }
}

/// "Коснитесь счёта" — экран довнесения переноса: список счетов текущей группы, тап выбирает
/// счёт списания/пополнения (направление вычисляется автоматически, см. ViewModel).
struct SelectAccountForTransfer: View {
    @State private var vm: SelectAccountForTransferViewModel
    @Environment(AlertManager.self) private var alert
    @Environment(PathSharedState.self) private var path

    init(transfer: PendingLinkedTransfer) {
        vm = SelectAccountForTransferViewModel(transfer: transfer)
    }

    var body: some View {
        List {
            if let sourceTransaction = vm.sourceTransaction {
                Section {
                    Text("Довнесите перенос: \(CurrencyFormatter().string(number: sourceTransaction.amountFrom, currency: sourceTransaction.accountFrom.currency))")
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(vm.accounts) { account in
                Button {
                    guard let (type, accountFrom, accountTo) = vm.transactionType(tappedAccount: account) else {
                        alert.error(ErrorModel(humanText: "Этот счёт нельзя использовать для довнесения"))
                        return
                    }
                    path.path.append(DraggableAccountRoute.completeLinkedTransfer(
                        type, accountFrom, accountTo, vm.transfer, vm.prefillAmount
                    ))
                } label: {
                    Text(account.name)
                }
            }
        }
        .navigationTitle("Коснитесь счёта")
        .task {
            do {
                try await vm.load()
            } catch {
                alert.error(error)
            }
        }
    }
}
