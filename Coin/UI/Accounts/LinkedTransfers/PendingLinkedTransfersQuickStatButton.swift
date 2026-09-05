//
//  PendingLinkedTransfersList.swift
//  Coin
//

import SwiftUI
import Factory
import GRDB
import OSLog

/// Кнопка-статистика "Переносы" в QuickStatisticView (та же колоночная раскладка, что у
/// "Расход"/"Баланс"/"Бюджет") — ведёт на PendingLinkedTransfersList. В отличие от бывшего бейджа
/// в тулбаре, держится в дереве постоянно (opacity/allowsHitTesting вместо if — см. историю
/// отладки: conditional-view ненадёжно вставлялось, когда условие становится true уже после
/// маунта), но теперь как равноправный элемент статистики, а не отдельная иконка.
struct PendingLinkedTransfersQuickStatButton: View {
    @State private var vm: PendingLinkedTransfersViewModel
    @Environment(PathSharedState.self) private var path

    init(accountGroup: AccountGroup) {
        vm = PendingLinkedTransfersViewModel(accountGroup: accountGroup)
    }

    var body: some View {
        Button {
            path.path.append(PendingLinkedTransfersRoute.list)
        } label: {
            VStack {
                Text("Переносы")
                    .bold()
                Text("\(vm.transfers.count)")
                    .foregroundStyle(vm.transfers.isEmpty ? Color.secondary : Color.orange)
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .opacity(vm.transfers.isEmpty ? 0.35 : 1)
        .allowsHitTesting(!vm.transfers.isEmpty)
        .task {
            do {
                for try await transfers in try await vm.observeTransfers() {
                    vm.apply(transfers)
                }
            } catch {
                pendingLinkedTransfersLogger.error("PendingLinkedTransfersQuickStatButton: \(String(describing: error), privacy: .public)")
            }
        }
    }
}
