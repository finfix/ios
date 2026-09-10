//
//  AccountCirclesViewModel.swift
//  Coin
//
//  Created by Илья on 25.03.2024.
//

import SwiftUI
import Factory
import OSLog
import GRDB

private let logger = Logger(subsystem: "Coin", category: "AccountCirclesViewModel")

@Observable
class AccountCirclesViewModel {

    @ObservationIgnored
    @Injected(\.service) private var service

    var accounts: [Account] = []
    var currentAccountGroup: AccountGroup? = nil

    /// Увеличивается при каждом переключении группы — часть `.id()` у AccountsTabView, чтобы
    /// полностью пересоздать сетку (а не просто обновить данные) при смене accountGroup.
    var reloadToken = 0

    /// Синхронная часть переключения группы — сама подгрузка счетов идёт живой подпиской
    /// (см. observeAccounts/applyObservedAccounts), вызывается из .task(id: accountGroup.id)
    /// в AccountCirclesView.
    // Плоский словарь id → счёт (родители + дети), пересобирается только когда реально меняются
    // accounts (applyObservedAccounts), а не на каждый вызов updateManualDrag/handleDrop — раньше
    // allAccounts.flatMap{...} гонялся заново на каждое движение пальца во время драга (десятки
    // раз в секунду), хотя accounts в этот момент не менялся вообще.
    @ObservationIgnored private var flatAccountsByID: [UUID: Account] = [:]

    // Временный дебаг — момент входа на экран (см. prepareForGroupSwitch), относительно которого
    // считаем миллисекунды во всех дебаг-логах этого файла (регистрация/очистка static locations
    // и т.д.), чтобы видеть точный тайминг событий друг относительно друга.
    @ObservationIgnored private var debugScreenEnteredAt: Date? = nil

    private func debugElapsedMs() -> String {
        guard let debugScreenEnteredAt else { return "?" }
        return String(Int(Date().timeIntervalSince(debugScreenEnteredAt) * 1000))
    }

    @MainActor
    func prepareForGroupSwitch(_ accountGroup: AccountGroup) {
        logger.debug("prepareForGroupSwitch: '\(accountGroup.name)'")
        currentAccountGroup = accountGroup
        accounts = []
        flatAccountsByID = [:]
        reloadToken += 1
        debugStaticLocations = [:]
        debugStaticLocationsStartedAt = nil
        debugScreenEnteredAt = Date()
        applyObservedAccountsCallCount = 0
        restartDebugStaticLocationsSnapshotLoop()
    }

    @ObservationIgnored private var debugSnapshotTask: Task<Void, Never>?

    // Раньше registerCreateTransactionLocation/clearCreateTransactionLocation писали прямо в
    // debugStaticLocations (@Observable) на каждый вызов — это перерисовывало AccountCirclesView
    // (а с ним и весь дебаг-оверлей с точками) на КАЖДУЮ регистрацию, добавляя лишнюю нагрузку и
    // шум в те самые тайминги, которые дебаг должен был просто показать, не искажая. Теперь
    // источник истины — createTransactionLocations (не Observable), а debugStaticLocations
    // обновляется снэпшотом раз в 200мс отдельным таском, только пока включён тумблер.
    private func restartDebugStaticLocationsSnapshotLoop() {
        debugSnapshotTask?.cancel()
        guard debugShowStaticLocations else { return }
        debugSnapshotTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.debugStaticLocations = self.createTransactionLocations
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }

    // Временный дебаг — считает, сколько раз ValueObservation реально прислала данные с момента
    // входа на экран, и меняется ли состав счетов между эмиссиями. Проверяем гипотезу, что
    // "пропадание" static locations через ~0.5с вызвано повторной эмиссией с другим составом
    // счетов (например, из-за пересчёта showingRemainder), а не самим фактом первого появления.
    @ObservationIgnored private var applyObservedAccountsCallCount = 0

    func observeAccounts(accountGroup: AccountGroup) -> AsyncValueObservation<[Account]> {
        service.observeAccounts(accountGroups: [accountGroup], visible: true)
    }

    @MainActor
    func applyObservedAccounts(_ flatAccounts: [Account], for accountGroup: AccountGroup) {
        guard currentAccountGroup?.id == accountGroup.id else { return }
        if debugShowStaticLocations {
            let previousIDs = Set(accounts.flatMap { [$0] + $0.childrenAccounts }.map(\.id))
            let newIDs = Set(flatAccounts.map(\.id))
            applyObservedAccountsCallCount += 1
        }
        accounts = Account.groupAccounts(flatAccounts)
        flatAccountsByID = Dictionary(uniqueKeysWithValues: accounts.flatMap { [$0] + $0.childrenAccounts }.map { ($0.id, $0) })
        // Форсируем пересоздание geometry-читающего слоя каждого кружка (см. geometryRefreshTrigger
        // и .id(vm.geometryRefreshTrigger) в DraggableAccountCircleItem) — пассивный
        // onGeometryChange иногда не перевызывается сам, даже если TabView(.page) реально
        // перекладывает контент (например, после повторной эмиссии ValueObservation с тем же
        // составом id, но обновлёнными данными): SwiftUI считает, что наблюдаемое значение не
        // изменилось. Пересоздание GeometryReader форсирует свежее чтение текущего layout.
        geometryRefreshTrigger += 1
    }

    /// См. applyObservedAccounts — бампается на каждую эмиссию ValueObservation, чтобы форсировать
    /// пересоздание geometry-читающего слоя кружков и тем самым перерегистрацию static locations.
    var geometryRefreshTrigger = 0

    /// Режим редактирования счетов ("трясущиеся" кружки с карандашиками, как на главном
    /// экране iOS) — общий для всех AccountsTabView на экране, включается долгим удержанием фона
    /// экрана (см. AccountCirclesView) и выключается однократным тапом на фон.
    var isEditMode = false

    // MARK: - Плавающая панель дочерних счетов (два слота)
    //
    // Панель открывается двойным тапом или секундной задержкой драга над родителем (см.
    // DraggableAccountCircleItem.handleHoverExpand). Раньше это был системный .popover — убрали,
    // потому что popover оказывается в отдельном presentation-контексте, куда нативный
    // drag-and-drop не дотягивается. Панель в той же иерархии, что и вся остальная сетка, и
    // ОБА её слота ВСЕГДА смонтированы в AccountCirclesView (скрываются через
    // opacity/allowsHitTesting, а не условным `if`) — см. AccountCirclesView.
    //
    // Слотов два, а не один, из-за конфликта двух сценариев:
    //  1) тащат ребёнка ИЗ уже открытой панели наружу (создание транзакции) — view этого ребёнка
    //     обязана пережить весь драг, иначе оборвётся её DragGesture и "призрак" замрёт на месте;
    //  2) во время ЭТОГО же драга наведение на ДРУГОГО родителя должно суметь открыть ЕГО панель
    //     (легитимный сценарий — precise-drop в конкретного ребёнка другого родителя).
    // Если бы слот был один, событие (2) подменяло бы его счёт и разрушало view из (1). Поэтому:
    // когда драг начинается от ребёнка текущего активного слота, этот слот "запирается"
    // (pinnedPanelSlot) — его account больше не меняется до конца драга, а новые открытия
    // (двойной тап/hover-expand на другого родителя) уходят во ВТОРОЙ, свободный слот.
    enum ExpandedPanelSlot { case primary, secondary }

    var primaryPanelAccount: Account? = nil
    var primaryPanelVisible = false
    var primaryPanelAnchorY: CGFloat? = nil

    var secondaryPanelAccount: Account? = nil
    var secondaryPanelVisible = false
    var secondaryPanelAnchorY: CGFloat? = nil

    /// Слот, который сейчас нельзя переиспользовать под другой счёт — держит живым ребёнка,
    /// которого прямо сейчас тащат наружу (см. updateManualDrag).
    var pinnedPanelSlot: ExpandedPanelSlot? = nil

    /// Слот, который в данный момент считается "текущим" для действий без явного указания слота
    /// (closeExpandedPanel() без параметра, обычное открытие).
    private var activePanelSlot: ExpandedPanelSlot = .primary

    var anyExpandedPanelVisible: Bool { primaryPanelVisible || secondaryPanelVisible }

    func account(for slot: ExpandedPanelSlot) -> Account? {
        slot == .primary ? primaryPanelAccount : secondaryPanelAccount
    }

    private func isVisible(_ slot: ExpandedPanelSlot) -> Bool {
        slot == .primary ? primaryPanelVisible : secondaryPanelVisible
    }

    private func setSlot(_ slot: ExpandedPanelSlot, account: Account, anchorY: CGFloat?) {
        switch slot {
        case .primary:
            primaryPanelAccount = account
            primaryPanelAnchorY = anchorY
            primaryPanelVisible = true
        case .secondary:
            secondaryPanelAccount = account
            secondaryPanelAnchorY = anchorY
            secondaryPanelVisible = true
        }
        activePanelSlot = slot
    }

    @MainActor
    func openExpandedPanel(for account: Account, anchorY: CGFloat?) {
        // Возврат в границы уже когда-то открытого (запертого) слота — просто обновляем его.
        if let pinnedPanelSlot, self.account(for: pinnedPanelSlot)?.id == account.id {
            setSlot(pinnedPanelSlot, account: account, anchorY: anchorY)
            return
        }
        // Запертый слот занят другим счётом — новое открытие уходит во ВТОРОЙ слот, чтобы не
        // разрушить его. Иначе (обычный случай, ничего не заперто) — используем primary.
        let targetSlot: ExpandedPanelSlot = (pinnedPanelSlot == .primary) ? .secondary : .primary
        setSlot(targetSlot, account: account, anchorY: anchorY)
    }

    // MARK: - Drag-and-drop (нативный .draggable/.dropDestination)
    //
    // Раньше позиции кружков трекались вручную (GeometryReader+PreferenceKey), а хит-тест —
    // distance-перебором с гистерезисом. Нативный dropDestination сам знает, над каким именно
    // элементом сейчас палец — никакого ручного трекинга координат/позиций больше не нужно.
    // Единственное сознательное упрощение поведения: подсветка цели теперь просто "палец сейчас
    // над этим кружком" (без валидации типа счёта на лету — она проверяется в момент дропа),
    // и перестановка в режиме редактирования больше не показывает живое "расступание" соседей
    // во время самого перетаскивания — соседи анимированно сдвигаются сразу после дропа.

    var highlitedAccount: Account? = nil

    func isHighligted(for account: Account) -> Bool {
        highlitedAccount == account
    }

    /// Прячет слот (opacity/allowsHitTesting в AccountCirclesView) — НЕ разрушает его account,
    /// поэтому безопасно вызывать даже для запертого (pinnedPanelSlot) слота: view его ребёнка
    /// остаётся в дереве, DragGesture не обрывается. `slot` по умолчанию — текущий активный.
    @MainActor
    func closeExpandedPanel(slot: ExpandedPanelSlot? = nil) {
        switch slot ?? activePanelSlot {
        case .primary: primaryPanelVisible = false
        case .secondary: secondaryPanelVisible = false
        }
    }

    @MainActor
    func setHighlighted(_ account: Account, targeted: Bool) {
        if targeted {
            // @Observable считает изменением любую запись, даже тем же значением — во время
            // драга setHighlighted может дёргаться на каждое движение пальца, так что без этой
            // проверки все view, читающие highlitedAccount, лишний раз инвалидировались бы на
            // каждый кадр, хотя цель не менялась.
            guard highlitedAccount != account else { return }
            highlitedAccount = account
            // Драг зашёл на какой-то счёт — прячем любой ВИДИМЫЙ слот панели, если это не
            // собственный ребёнок этого слота (иначе он закрывался бы сам на себе, стоило бы
            // навести на любого его ребёнка). Прячем именно скрытием (opacity), а не сбросом
            // account — безопасно для обоих слотов, включая запертый.
            if primaryPanelVisible, let primaryPanelAccount, !primaryPanelAccount.childrenAccounts.contains(where: { $0.id == account.id }) {
                primaryPanelVisible = false
            }
            if secondaryPanelVisible, let secondaryPanelAccount, !secondaryPanelAccount.childrenAccounts.contains(where: { $0.id == account.id }) {
                secondaryPanelVisible = false
            }
        } else if highlitedAccount == account {
            highlitedAccount = nil
        }
    }

    /// Точка входа для .dropDestination(action:) — теперь только перестановка (режим
    /// редактирования): создание транзакции больше не идёт через нативный drag (см. ниже,
    /// MARK: Создание транзакции), поэтому здесь веток по isEditMode уже не нужно.
    @MainActor
    func handleDrop(_ dragged: DraggedAccount, onto targetAccount: Account) async {
        highlitedAccount = nil
        primaryPanelVisible = false
        secondaryPanelVisible = false
        guard let draggedAccount = flatAccountsByID[dragged.accountID] else { return }
        await confirmReorder(dragged: draggedAccount, target: targetAccount)
    }

    /// Перенесено из DraggableAccountCircleItem — выбор типа транзакции по комбинации типов
    /// перетащенных друг на друга счетов (earnings→regular=доход, regular→regular=перевод,
    /// regular→expense=расход) и разрешение родительских счетов в конкретные дочерние.
    @MainActor
    private func confirmDraggableDrop(from draggedAccount: Account, onto staticAccount: Account, path: Binding<NavigationPath>) {
        var transactionType: TransactionType?
        switch true {
        case draggedAccount.id == staticAccount.id: break
        case draggedAccount.type == .earnings && staticAccount.type == .regular: transactionType = .income
        case draggedAccount.type == .regular && staticAccount.type == .regular: transactionType = .transfer
        case draggedAccount.type == .regular && staticAccount.type == .expense: transactionType = .consumption
        default: break
        }

        guard let transactionType else { return }

        var accountFrom: Account? = draggedAccount
        if draggedAccount.isParent {
            accountFrom = draggedAccount.childrenAccounts.first
        }

        var accountTo: Account? = staticAccount
        if staticAccount.isParent {
            accountTo = staticAccount.childrenAccounts.first(where: { $0.currency == accountFrom?.currency })
                ?? staticAccount.childrenAccounts.first
        }

        guard let accountFrom, let accountTo else { return }
        path.wrappedValue.append(DraggableAccountRoute.createTransaction(transactionType, accountFrom, accountTo))
    }

    // MARK: - Создание транзакции обычным DragGesture (без задержки .draggable)
    //
    // Перестановка (режим редактирования) осталась на нативном .draggable/.dropDestination —
    // там небольшая задержка перед "поднятием" уместна, как при перестановке иконок на Home
    // Screen. А вот создание транзакции должно начинаться сразу по движению пальца — у
    // .draggable на тач-экране всегда есть системная эвристика "прижать-и-подождать" перед
    // стартом драга (не настраивается публичным API), и с мышью на Mac это не проявляется, а
    // пальцем ощущается как "залипание". Здесь — свой, ЛЁГКИЙ хит-тест (без гистерезиса,
    // заморозок и автолистания краёв старой системы): просто "какой кружок ближе всего в
    // пределах triggerZone".

    @ObservationIgnored private var createTransactionLocations: [UUID: CGPoint] = [:]
    let createTransactionTriggerZone: CGFloat = 50

    // Временный дебаг — см. Developer Tools → тумблеры "Дебаг ручного драга счетов" / "Показывать
    // static locations". Логирует каждую регистрацию позиции и каждый хит-тест, чтобы понять,
    // почему создание транзакции иногда не находит цель сразу после появления счетов на экране.
    @ObservationIgnored @AppStorage("debugManualDrag") private var debugManualDrag = false
    @ObservationIgnored @AppStorage("debugShowStaticLocations") private var debugShowStaticLocations = false

    // Зеркало createTransactionLocations, но НЕ @ObservationIgnored — специально для отрисовки на
    // экране (сама createTransactionLocations игнорируется Observation намеренно, чтобы не
    // перерисовывать все view на каждую регистрацию позиции). Заполняется только когда включён
    // дебаг-тумблер, чтобы не тратить время на лишние SwiftUI-инвалидации в обычном режиме.
    var debugStaticLocations: [UUID: CGPoint] = [:]
    // Момент первой регистрации позиции с момента появления/пересоздания экрана (см.
    // prepareForGroupSwitch) — индикатор в UI показывает именно его, чтобы можно было сопоставить
    // с моментом, когда счета визуально появились на экране.
    var debugStaticLocationsStartedAt: Date? = nil

    var draggableAccount: Account? = nil
    var draggableLocation: CGPoint? = nil

    func registerCreateTransactionLocation(_ location: CGPoint, for accountID: UUID) {
        createTransactionLocations[accountID] = location
    }

    func clearCreateTransactionLocation(for accountID: UUID) {
        createTransactionLocations.removeValue(forKey: accountID)
    }

    /// Есть ли зарегистрированный счёт рядом с точкой — используется фоновым жестом выхода из
    /// режима редактирования (см. AccountCirclesView), чтобы не гасить isEditMode, если тап на
    /// самом деле попал по кружку: .simultaneousGesture фона получает события параллельно с
    /// TapGesture кружка, и без этой проверки могла возникнуть гонка, где isEditMode гасился
    /// раньше, чем срабатывал собственный обработчик тапа кружка.
    func hasRegisteredAccount(near location: CGPoint) -> Bool {
        createTransactionLocations.values.contains {
            abs($0.x - location.x) < createTransactionTriggerZone && abs($0.y - location.y) < createTransactionTriggerZone
        }
    }

    @MainActor
    func updateManualDrag(location: CGPoint, draggedAccount: Account) {
        if draggableAccount?.id != draggedAccount.id {
            draggableAccount = draggedAccount
            // Новый драг начался — если тащат ребёнка ТЕКУЩЕГО активного (видимого) слота панели,
            // запираем этот слот: наведение на другого родителя (hover-expand) больше не сможет
            // подменить его account и разрушить эту view вместе с живым DragGesture — такое
            // открытие уйдёт во второй слот (см. openExpandedPanel).
            if isVisible(activePanelSlot), let activeAccount = account(for: activePanelSlot),
               activeAccount.childrenAccounts.contains(where: { $0.id == draggedAccount.id }) {
                pinnedPanelSlot = activePanelSlot
            }
        }
        if draggableLocation != location {
            draggableLocation = location
        }

        // Пока хотя бы один слот панели виден, целями дропа могут быть ТОЛЬКО дети видимых
        // слотов — иначе счета основной сетки, физически скрытые под полупрозрачным задником
        // панели, всё равно могли бы поймать дроп при отпускании пальца (для пользователя это
        // выглядело бы как "отпустил в пустоту, а транзакция создалась не туда"). Когда оба слота
        // скрыты — обычная логика, целью может быть любой зарегистрированный счёт.
        var allowedTargetIDs: Set<UUID> = []
        if primaryPanelVisible, let primaryPanelAccount { allowedTargetIDs.formUnion(primaryPanelAccount.childrenAccounts.map(\.id)) }
        if secondaryPanelVisible, let secondaryPanelAccount { allowedTargetIDs.formUnion(secondaryPanelAccount.childrenAccounts.map(\.id)) }
        let hasRestriction = primaryPanelVisible || secondaryPanelVisible

        var best: (account: Account, distance: CGFloat)?
        for (id, point) in createTransactionLocations {
            guard id != draggedAccount.id,
                  !hasRestriction || allowedTargetIDs.contains(id),
                  abs(point.x - location.x) < createTransactionTriggerZone,
                  abs(point.y - location.y) < createTransactionTriggerZone,
                  let candidate = flatAccountsByID[id],
                  isValidTransactionTarget(from: draggedAccount, to: candidate) else { continue }
            let distance = hypot(point.x - location.x, point.y - location.y)
            if best == nil || distance < best!.distance {
                best = (candidate, distance)
            }
        }

        if debugManualDrag {
            logger.debug("updateManualDrag: location=\(String(describing: location)) locationsRegistered=\(self.createTransactionLocations.count) flatAccountsByID=\(self.flatAccountsByID.count) best=\(best?.account.name ?? "nil")")
        }

        if let best {
            setHighlighted(best.account, targeted: true)
        } else if let highlitedAccount {
            setHighlighted(highlitedAccount, targeted: false)
        }
    }

    private func isValidTransactionTarget(from draggedAccount: Account, to staticAccount: Account) -> Bool {
        switch true {
        case draggedAccount.type == .earnings && staticAccount.type == .regular: true
        case draggedAccount.type == .regular && staticAccount.type == .regular: true
        case draggedAccount.type == .regular && staticAccount.type == .expense: true
        default: false
        }
    }

    @MainActor
    func confirmManualDrag(path: Binding<NavigationPath>) {
        defer {
            draggableAccount = nil
            draggableLocation = nil
            // Драг закончен — оба слота больше не нужны, снимаем "замок" и прячем оба безусловно
            // (и при успешном дропе, и при промахе — палец отпущен не над целью).
            pinnedPanelSlot = nil
            primaryPanelVisible = false
            secondaryPanelVisible = false
        }
        guard let draggedAccount = draggableAccount, let target = highlitedAccount else {
            highlitedAccount = nil
            return
        }
        confirmDraggableDrop(from: draggedAccount, onto: target, path: path)
        highlitedAccount = nil
    }

    /// Перемещает перетаскиваемый счёт рядом с целевым — на бэк улетает ровно одно обновление
    /// (rank только у самого перемещённого счёта), остальные счета секции не трогаются: они
    /// остаются в прежнем относительном порядке друг относительно друга, поэтому их текущий
    /// rank и так валиден в новом расположении.
    @MainActor
    private func confirmReorder(dragged draggedAccount: Account, target targetAccount: Account) async {
        guard draggedAccount.id != targetAccount.id, draggedAccount.type == targetAccount.type else { return }

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
        } catch {
            logger.error("confirmReorder: не удалось сохранить новый rank — \(error.localizedDescription)")
        }
    }
}
