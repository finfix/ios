//
//  PendingLinkedTransfersList.swift
//  Coin
//

import SwiftUI
import Factory
import GRDB
import OSLog

private let logger = Logger(subsystem: "Coin", category: "PendingLinkedTransfers")

enum PendingLinkedTransfersRoute: Hashable {
    case list
    case completeLinkedTransfer(PendingLinkedTransfer)
}

@Observable
class PendingLinkedTransfersViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service

    let accountGroup: AccountGroup

    init(accountGroup: AccountGroup) {
        self.accountGroup = accountGroup
    }

    var transfers: [PendingLinkedTransfer] = []
    /// Разрешённая на конкретный перенос транзакция-инициатор — резолвится лениво в момент показа строки.
    var resolvedTransactions: [UUID: Transaction] = [:]
    /// Мой счёт-получатель (targetAccountID) — показывается прямо в строке списка, чтобы сразу
    /// было видно, к какому СВОЕМУ счёту довносится сумма, не дожидаясь перехода на экран выбора
    /// (сама транзакция-инициатор — из ДРУГОЙ группы счетов, и это легко перепутать).
    var resolvedTargetAccounts: [UUID: Account] = [:]

    /// Только переносы, где меня ждут: мой счёт-получатель (targetAccountID) лежит в ВЫБРАННОЙ
    /// группе. Намеренно НЕ показываем здесь переносы, где я источник (accountGroupID совпадает
    /// с этой группой) — это уведомление для того, кому нужно ДЕЙСТВОВАТЬ (довнести), а не для
    /// того, кто уже знает, что сам создал перенос.
    func observeTransfers() async throws -> AsyncValueObservation<[PendingLinkedTransfer]> {
        let myAccountIDs = try await service.getAccounts(accountGroups: [accountGroup]).map(\.id)
        logger.debug("observeTransfers: accountGroup=\(self.accountGroup.name, privacy: .public) (\(self.accountGroup.id.uuidString, privacy: .public)) myAccountIDs=\(myAccountIDs.map { $0.uuidString.prefix(8).description }, privacy: .public)")
        return service.observePendingLinkedTransfers(accountGroups: [], myAccountIDs: myAccountIDs)
    }

    @MainActor
    func apply(_ transfers: [PendingLinkedTransfer]) {
        logger.debug("apply: raw=\(transfers.count) pending=\(transfers.filter { $0.status == .pending }.count) for accountGroup=\(self.accountGroup.name, privacy: .public)")
        self.transfers = transfers.filter { $0.status == .pending }
        for transfer in self.transfers where resolvedTransactions[transfer.id] == nil {
            Task { await resolveTransaction(for: transfer) }
        }
        for transfer in self.transfers where resolvedTargetAccounts[transfer.id] == nil {
            Task { await resolveTargetAccount(for: transfer) }
        }
    }

    @MainActor
    private func resolveTransaction(for transfer: PendingLinkedTransfer) async {
        guard resolvedTransactions[transfer.id] == nil else { return }
        guard let transaction = try? await service.getTransactions(ids: [transfer.sourceTransactionID]).first else { return }
        resolvedTransactions[transfer.id] = transaction
    }

    @MainActor
    private func resolveTargetAccount(for transfer: PendingLinkedTransfer) async {
        guard resolvedTargetAccounts[transfer.id] == nil else { return }
        guard let account = try? await service.getAccounts(ids: [transfer.targetAccountID]).first else { return }
        resolvedTargetAccounts[transfer.id] = account
    }

    func ignore(_ transfer: PendingLinkedTransfer) async throws {
        try await service.ignoreLinkedTransfer(transfer)
    }
}

/// Кнопка-уведомление в тулбаре AccountCirclesView — видна только если есть хотя бы один
/// pending-перенос, ведёт на PendingLinkedTransfersList.
struct PendingLinkedTransfersBadge: View {
    @State private var vm: PendingLinkedTransfersViewModel
    @Environment(PathSharedState.self) private var path

    init(accountGroup: AccountGroup) {
        vm = PendingLinkedTransfersViewModel(accountGroup: accountGroup)
    }

    var body: some View {
        // Кнопка держится в дереве ПОСТОЯННО (не под if !vm.transfers.isEmpty) — SwiftUI
        // ненадёжно вставляет/убирает conditional-view внутри тулбара при первом появлении,
        // если условие становится true уже ПОСЛЕ маунта (см. отладку: с `if` бейдж не появлялся
        // даже когда vm.transfers реально был непустой, пока условие не убрали). Видимость и
        // интерактивность вместо этого регулируются opacity/allowsHitTesting.
        Button {
            path.path.append(PendingLinkedTransfersRoute.list)
        } label: {
            Image(systemName: "arrow.left.arrow.right.circle.fill")
                .foregroundStyle(.orange)
                .overlay(alignment: .topTrailing) {
                    Text("\(vm.transfers.count)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Circle().fill(.red))
                        .offset(x: 8, y: -8)
                }
        }
        .opacity(vm.transfers.isEmpty ? 0 : 1)
        .allowsHitTesting(!vm.transfers.isEmpty)
        .task {
            logger.debug("PendingLinkedTransfersBadge: .task запустился")
            do {
                for try await transfers in try await vm.observeTransfers() {
                    vm.apply(transfers)
                }
            } catch {
                logger.error("PendingLinkedTransfersBadge: \(String(describing: error), privacy: .public)")
            }
        }
    }
}

/// Отдельная view (а не inline-выражение в List) — иначе компилятор не справляется с выводом
/// типов внутри вложенного ForEach/Section/List (реальный краш type-checker'а на этом файле).
private struct PendingLinkedTransferRow: View {
    let transaction: Transaction
    let targetAccount: Account?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TransactionRow(transaction: TransactionListRowData(transaction))
            if let targetAccount {
                Label("К счёту «\(targetAccount.name)»", systemImage: "arrow.turn.down.right")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .contentShape(Rectangle())
    }
}

struct PendingLinkedTransfersList: View {
    @State private var vm: PendingLinkedTransfersViewModel
    @Environment(AlertManager.self) private var alert
    @Environment(PathSharedState.self) private var path

    init(accountGroup: AccountGroup) {
        vm = PendingLinkedTransfersViewModel(accountGroup: accountGroup)
    }

    /// Переносы, для которых уже резолвилась транзакция-инициатор, сгруппированные по дню —
    /// тот же принцип, что и TransactionsList.transactionItems/isNewSection, только тут список
    /// короткий и без пагинации, так что группировку проще держать прямо в body.
    private var groupedByDay: [(day: Date, items: [(transfer: PendingLinkedTransfer, transaction: Transaction)])] {
        let resolved = vm.transfers.compactMap { transfer -> (PendingLinkedTransfer, Transaction)? in
            guard let transaction = vm.resolvedTransactions[transfer.id] else { return nil }
            return (transfer, transaction)
        }
        let grouped = Dictionary(grouping: resolved) { $0.1.dateTransaction.stripTime() }
        return grouped
            .map { (day: $0.key, items: $0.value.sorted { $0.1.dateTransaction > $1.1.dateTransaction }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        List {
            if vm.transfers.isEmpty {
                Text("Нет переносов, ожидающих довнесения")
                    .foregroundStyle(.secondary)
            }
            ForEach(groupedByDay, id: \.day) { section in
                Section {
                    ForEach(section.items, id: \.transfer.id) { item in
                        Button {
                            path.path.append(PendingLinkedTransfersRoute.completeLinkedTransfer(item.transfer))
                        } label: {
                            PendingLinkedTransferRow(transaction: item.transaction, targetAccount: vm.resolvedTargetAccounts[item.transfer.id])
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button("Не переносить", role: .destructive) {
                                Task {
                                    do {
                                        try await vm.ignore(item.transfer)
                                    } catch {
                                        alert.error(error)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text(section.day.formatted(date: .complete, time: .omitted).uppercased())
                }
            }
        }
        .navigationTitle("Переносы")
        .task {
            do {
                for try await transfers in try await vm.observeTransfers() {
                    vm.apply(transfers)
                }
            } catch {
                alert.error(error)
            }
        }
    }
}

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
                        type, accountFrom, accountTo, transfer, sourceTransaction.amountFrom
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
