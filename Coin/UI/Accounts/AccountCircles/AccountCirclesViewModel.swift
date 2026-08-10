//
//  AccountCirclesViewModel.swift
//  Coin
//
//  Created by Илья on 25.03.2024.
//

import SwiftUI
import Factory
import OSLog

private let logger = Logger(subsystem: "Coin", category: "AccountCirclesViewModel")

@Observable
class AccountCirclesViewModel {
    
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var accounts: [Account] = []
    var currentAccountGroup: AccountGroup? = nil

    /// Увеличивается при каждой успешной загрузке счетов. Используется как часть `.id()`
    /// у AccountsTabView, чтобы форсировать полный remount сетки кружков — иначе после
    /// возврата с другого экрана (навигация push/pop приостанавливает и заново запускает
    /// `.task`) SwiftUI иногда не пересчитывает GeometryReader/onPreferenceChange у уже
    /// существующих (по значению совпадающих) DraggableAccountCircleItem, из-за чего
    /// staticLocations не переинициализируются и перетаскивание перестаёт находить цель.
    var reloadToken = 0

    @MainActor
    func load(accountGroup: AccountGroup) async throws {
        logger.debug("load: начало для группы '\(accountGroup.name)'")
        self.currentAccountGroup = accountGroup
        // Очищаем счета немедленно, чтобы не было фантомных регистраций в staticLocations
        // пока AccountsTabView пересоздаётся с новой группой (из-за .id(groupID))
        self.accounts = []
        let loaded = try await service.getAccounts(accountGroups: [accountGroup], visible: true)
        guard currentAccountGroup?.id == accountGroup.id else {
            logger.warning("load: отменён для '\(accountGroup.name)' — currentAccountGroup уже '\(self.currentAccountGroup?.name ?? "nil")'")
            return
        }
        deleteStaticLocations()
        self.accounts = Account.groupAccounts(loaded)
        reloadToken += 1
    }

    var highlitedAccount: Account? = nil

    /// Режим редактирования счетов ("трясущиеся" кружки с карандашиками, как на главном
    /// экране iOS) — общий для всех AccountsTabView на экране, включается долгим тапом на
    /// любой кружок и выключается кнопкой "Готово".
    var isEditMode = false

    var draggableLocation: CGPoint? = nil
    var draggableAccount: Account? = nil
    @ObservationIgnored var staticLocations: [UUID: CGPoint] = [:]

    let triggerZone: CGFloat = 50

    func initializateStaticLocations(location: CGPoint, for account: Account, in accountGroup: AccountGroup) {
        guard accountGroup.id == currentAccountGroup?.id else {
            return
        }
        self.staticLocations[account.id] = location
    }

    func deleteStaticLocations() {
        self.staticLocations = [UUID: CGPoint]()
    }
    
    func updateDraggableLocation(location draggableLocation: CGPoint, for draggableAccount: Account) {
        self.draggableLocation = draggableLocation
        self.draggableAccount = draggableAccount

        // Строим плоский список всех счетов (включая дочерние) для поиска по UUID
        let allAccounts = accounts.flatMap { [$0] + $0.childrenAccounts }

        var needReset = false
        for (accountID, staticLocation) in staticLocations
            where abs(staticLocation.x - draggableLocation.x) < triggerZone
            && abs(staticLocation.y - draggableLocation.y) < triggerZone {
            guard let staticAccount = allAccounts.first(where: { $0.id == accountID }) else { continue }
            switch (true) {
            case staticAccount.id == draggableAccount.id: needReset = true
            case draggableAccount.type == .earnings && staticAccount.type == .regular: highlitedAccount = staticAccount
            case draggableAccount.type == .regular && staticAccount.type == .regular: highlitedAccount = staticAccount
            case draggableAccount.type == .regular && staticAccount.type == .expense: highlitedAccount = staticAccount
            default: needReset = true
            }
        }
        if needReset {
            self.highlitedAccount = nil
        }
    }
    
    func isHighligted(for account: Account) -> Bool {
        self.highlitedAccount == account
    }

    // MARK: - Reorder (режим редактирования)

    var reorderDraggableAccount: Account? = nil
    var reorderDraggableLocation: CGPoint? = nil
    var reorderTargetAccount: Account? = nil

    // Насколько новый кандидат должен быть БЛИЖЕ текущей цели, чтобы цель сменилась. Это
    // подстраховка НА СЛУЧАЙ пограничных ситуаций — но основная защита от зацикливания в
    // том, что цель ищется не по живым (см. ниже reorderReferenceLocations), а по
    // ЗАМОРОЖЕННЫМ на момент начала перетаскивания позициям, которые reflow (см.
    // liveReorderedAccounts) не трогает. Если бы цель искалась по живым staticLocations,
    // 15pt гистерезиса всё равно не хватило бы: reflow сдвигает соседей на целую ячейку
    // сетки (~90pt), что легко перекрывает любой разумный запас.
    let reorderHysteresis: CGFloat = 15

    // Снимок staticLocations на момент начала конкретного перетаскивания. Пока счёт летит,
    // liveReorderedAccounts двигает соседей по экрану, и их staticLocations в ответ тоже
    // меняются — если искать цель по этим живым координатам, получается петля обратной связи
    // (цель сменилась → сетка сдвинулась → это меняет ближайшего кандидата → цель снова
    // меняется, и так по кругу). Поэтому цель всегда определяется по позициям на МОМЕНТ
    // начала жеста. Дополняется (не перезаписывается) при автолистании на новую страницу —
    // см. mergeIntoReorderReferenceLocations.
    @ObservationIgnored private var reorderReferenceLocations: [UUID: CGPoint]?

    // Собственная позиция перетаскиваемого счёта на момент начала жеста. Пока палец не
    // отошёл от неё дальше triggerZone, цель намеренно не ищем — иначе сосед, оказавшийся
    // в пределах triggerZone от ИСХОДНОГО места самого перетаскиваемого счёта, становится
    // целью сразу при взятии кружка, ещё до какого-либо реального перемещения.
    @ObservationIgnored private var reorderPickupLocation: CGPoint?

    /// Подмешивает свежие (актуальные) позиции — например, только что появившихся после
    /// автолистания счетов новой страницы — в замороженный снимок. Устаревшие записи для
    /// счетов, которых сейчас нет на экране, к этому моменту уже вычищены из staticLocations
    /// через `.onDisappear` у DraggableAccountCircleItem, так что коллизий по координатам
    /// (два разных счёта на одном и том же месте) быть не должно.
    func mergeIntoReorderReferenceLocations() {
        guard reorderReferenceLocations != nil else { return }
        reorderReferenceLocations?.merge(staticLocations) { _, new in new }
    }

    // Только для графического дебага (debugShowStaticLocations) — снимок того, что именно
    // вычислила последняя итерация updateReorderDraggableLocation: кто был лучшим кандидатом
    // и на каком расстоянии, кто была прежняя цель и на каком расстоянии от неё, поменялась
    // ли цель в этот раз. Не влияет на саму логику, только для визуализации.
    struct ReorderDebugSnapshot {
        var bestCandidateName: String?
        var bestCandidateDistance: CGFloat?
        var currentTargetName: String?
        var currentTargetDistance: CGFloat?
        var targetChanged: Bool
    }
    var reorderDebugSnapshot: ReorderDebugSnapshot?

    func updateReorderDraggableLocation(location: CGPoint, for account: Account) {
        if reorderDraggableAccount == nil {
            reorderReferenceLocations = staticLocations
            reorderPickupLocation = staticLocations[account.id]
        }
        reorderDraggableAccount = account
        reorderDraggableLocation = location

        let referenceLocations = reorderReferenceLocations ?? staticLocations
        let allAccounts = accounts.flatMap { [$0] + $0.childrenAccounts }

        // Пока палец не отошёл от исходного места счёта дальше triggerZone — цель не ищем,
        // чтобы не подхватывать соседа сразу при взятии кружка.
        if let pickupLocation = reorderPickupLocation,
           hypot(pickupLocation.x - location.x, pickupLocation.y - location.y) < triggerZone {
            reorderTargetAccount = nil
            reorderDebugSnapshot = ReorderDebugSnapshot(
                bestCandidateName: nil,
                bestCandidateDistance: nil,
                currentTargetName: nil,
                currentTargetDistance: nil,
                targetChanged: false
            )
            return
        }

        var bestCandidate: (account: Account, distance: CGFloat)?
        for (accountID, staticLocation) in referenceLocations {
            guard accountID != account.id,
                  abs(staticLocation.x - location.x) < triggerZone,
                  abs(staticLocation.y - location.y) < triggerZone,
                  let staticAccount = allAccounts.first(where: { $0.id == accountID }),
                  staticAccount.type == account.type else { continue }
            let distance = hypot(staticLocation.x - location.x, staticLocation.y - location.y)
            if bestCandidate == nil || distance < bestCandidate!.distance {
                bestCandidate = (staticAccount, distance)
            }
        }

        let previousTarget = reorderTargetAccount
        var currentDistance: CGFloat?
        if let currentTarget = reorderTargetAccount, let currentLocation = referenceLocations[currentTarget.id] {
            currentDistance = hypot(currentLocation.x - location.x, currentLocation.y - location.y)
        }

        guard let bestCandidate else {
            reorderTargetAccount = nil
            reorderDebugSnapshot = ReorderDebugSnapshot(
                bestCandidateName: nil,
                bestCandidateDistance: nil,
                currentTargetName: previousTarget?.name,
                currentTargetDistance: currentDistance,
                targetChanged: previousTarget != nil
            )
            return
        }

        var didChange = false
        if let currentTarget = reorderTargetAccount, currentTarget.id != bestCandidate.account.id {
            if let currentDistance {
                if bestCandidate.distance < currentDistance - reorderHysteresis {
                    reorderTargetAccount = bestCandidate.account
                    didChange = true
                }
            } else {
                // У прежней цели пропала позиция (например, её staticLocations запись
                // почистилась) — сравнивать по гистерезису не с чем, переключаемся сразу.
                reorderTargetAccount = bestCandidate.account
                didChange = true
            }
        } else if reorderTargetAccount == nil {
            reorderTargetAccount = bestCandidate.account
            didChange = true
        }

        reorderDebugSnapshot = ReorderDebugSnapshot(
            bestCandidateName: bestCandidate.account.name,
            bestCandidateDistance: bestCandidate.distance,
            currentTargetName: previousTarget?.name,
            currentTargetDistance: currentDistance,
            targetChanged: didChange
        )
    }

    func isReorderTarget(_ account: Account) -> Bool {
        reorderTargetAccount == account
    }

    /// Перемещает перетаскиваемый счёт рядом с целевым — на бэк улетает ровно одно
    /// обновление (rank только у самого перемещённого счёта), остальные счета секции
    /// не трогаются: они остаются в прежнем относительном порядке друг относительно
    /// друга, поэтому их текущий rank и так валиден в новом расположении.
    @MainActor
    func confirmReorder() async {
        defer {
            reorderDraggableAccount = nil
            reorderDraggableLocation = nil
            reorderTargetAccount = nil
            reorderReferenceLocations = nil
            reorderPickupLocation = nil
        }
        guard let draggedAccount = reorderDraggableAccount,
              let targetAccount = reorderTargetAccount,
              draggedAccount.id != targetAccount.id else { return }

        let sameTypeSorted = accounts
            .filter { $0.type == draggedAccount.type }
            .sorted { $0.rank < $1.rank }
        guard let originalDraggedIndex = sameTypeSorted.firstIndex(where: { $0.id == draggedAccount.id }),
              let originalTargetIndex = sameTypeSorted.firstIndex(where: { $0.id == targetAccount.id }) else { return }
        let movingForward = originalDraggedIndex < originalTargetIndex

        // Соседи без перетаскиваемого счёта — их порядок друг относительно друга не меняется
        let siblings = sameTypeSorted.filter { $0.id != draggedAccount.id }
        guard let targetIndex = siblings.firstIndex(where: { $0.id == targetAccount.id }) else { return }

        let prevRank: String?
        let nextRank: String?
        if movingForward {
            // Уносим счёт "вперёд" — вставляем сразу ПОСЛЕ целевого
            prevRank = siblings[targetIndex].rank
            nextRank = targetIndex + 1 < siblings.count ? siblings[targetIndex + 1].rank : nil
        } else {
            // Уносим счёт "назад" — вставляем сразу ПЕРЕД целевым
            prevRank = targetIndex > 0 ? siblings[targetIndex - 1].rank : nil
            nextRank = siblings[targetIndex].rank
        }

        let newRank = Rank.between(prevRank, nextRank)
        guard newRank != draggedAccount.rank else { return }

        var updatedAccount = draggedAccount
        updatedAccount.rank = newRank

        do {
            try await service.updateAccount(newAccount: updatedAccount, oldAccount: draggedAccount)
            if let group = currentAccountGroup {
                try await load(accountGroup: group)
            }
        } catch {
            logger.error("confirmReorder: не удалось сохранить новый rank — \(error.localizedDescription)")
        }
    }
}
