//
//  PendingLinkedTransfersList.swift
//  Coin
//

import SwiftUI
import Factory
import GRDB
import OSLog

/// Резолвит данные, нужные для завершения ОДНОГО конкретного переноса (мой счёт-мост,
/// исходная транзакция), и настраивает переиспользуемый AccountCirclePicker под этот сценарий —
/// сама логика выбора счёта/навигации переиспользуемого компонента этого сценария не знает.
struct CompleteLinkedTransferPicker: View {
    let transfer: PendingLinkedTransfer

    @Injected(\.service) private var service
    @Environment(AlertManager.self) private var alert
    @Environment(PathSharedState.self) private var path

    @State private var myBridgeAccount: Account?
    @State private var accounts: [Account] = []
    @State private var sourceTransaction: Transaction?

    var body: some View {
        Group {
            if let myBridgeAccount, let sourceTransaction {
                AccountCirclePicker(
                    title: "Коснитесь счёта",
                    accounts: accounts,
                    isDisabled: { candidate in
                        candidate.id == myBridgeAccount.id ||
                        transfer.resolveCompletion(
                            tappedAccount: candidate,
                            myBridgeAccount: myBridgeAccount,
                            sourceTransaction: sourceTransaction
                        ) == nil
                    },
                    highlightedAccountID: myBridgeAccount.id,
                    // Направление денег зависит от роли моста в итоговой транзакции — та же
                    // проверка, что и внутри resolveCompletion (sourceTransaction.accountTo ==
                    // sourceAccountID ⟹ у меня мост продолжает путь ИЗ себя, деньги уходят
                    // "отсюда", а не приходят "сюда").
                    highlightedAccountLabel: sourceTransaction.accountTo.id == transfer.sourceAccountID ? "отсюда" : "сюда"
                ) { tappedAccount in
                    guard let (type, accountFrom, accountTo) = transfer.resolveCompletion(
                        tappedAccount: tappedAccount,
                        myBridgeAccount: myBridgeAccount,
                        sourceTransaction: sourceTransaction
                    ) else {
                        alert.error(ErrorModel(humanText: "Этот счёт нельзя использовать для довнесения"))
                        return
                    }
                    path.path.append(DraggableAccountRoute.completeLinkedTransfer(
                        type, accountFrom, accountTo, transfer, sourceTransaction.amountFrom, sourceTransaction.dateTransaction
                    ))
                }
            } else {
                ProgressView()
            }
        }
        .task {
            do {
                guard let myBridgeAccount = try await service.getAccounts(ids: [transfer.targetAccountID]).first else {
                    throw ErrorModel(humanText: "Не нашли свой счёт-мост")
                }
                self.myBridgeAccount = myBridgeAccount
                sourceTransaction = try await service.getTransactions(ids: [transfer.sourceTransactionID]).first
                // getAccounts возвращает плоский список — childrenAccounts у каждого элемента
                // всегда пуст, вложенность строит только groupAccounts (см. AccountCirclesViewModel.
                // applyObservedAccounts). Без него AccountCirclePicker не отличит родителя от
                // обычного счёта и вместо панели дочерних сразу вызовет onSelect.
                accounts = Account.groupAccounts(try await service.getAccounts(accountGroups: [myBridgeAccount.accountGroup], visible: true))
            } catch {
                alert.error(error)
            }
        }
    }
}
