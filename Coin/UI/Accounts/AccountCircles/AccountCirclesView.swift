//
//  AccountCircleView.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI
import OSLog
import Factory

let accountCirclesViewLogger = Logger(subsystem: "Coin", category: "AccountCirclesView")




struct AccountCirclesView: View {
    
    @Environment(AlertManager.self) private var alert
    @Environment(AccountGroupSharedState.self) private var selectedAccountGroup
    // Не свой NavigationStack — этот экран всегда встроен в NavigationStack, который уже создаёт
    // AccountCirclesTab (вложенный NavigationStack внутри другого приводил к неустойчивым багам
    // с навигацией — экраны копились в стеке, dismiss возвращал не туда).
    @Environment(PathSharedState.self) private var path
    @State private var vm = AccountCirclesViewModel()
    @AppStorage("debugShowStaticLocations") private var debugShowStaticLocations = false
    // Долгое удержание фона → вход в режим редактирования; см. .simultaneousGesture ниже.
    @State private var editModeLongPressTask: Task<Void, Never>?
    @State private var editModeLongPressFired = false
    // Точка касания в момент старта жеста и флаг "палец поехал" — чтобы отличить настоящее
    // удержание на месте от перелистывания/скролла (тот жест тоже держит палец дольше 500мс,
    // но при этом двигается).
    @State private var editModeLongPressStart: CGPoint?
    @State private var editModeLongPressMoved = false

    let horizontalSpacing: CGFloat = 10

    var body: some View {
        @Bindable var path = path
        VStack {
            QuickStatisticView(selectedAccountGroup: selectedAccountGroup.selectedAccountGroup)
                .onAppear {
                    if debugShowStaticLocations {
                        accountCirclesViewLogger.debug("AccountCirclesView.body: (пере)появился — id=\(String(describing: ObjectIdentifier(vm))), isLogin=\(AuthStorage.shared.isLogin), selectedGroup=\(selectedAccountGroup.selectedAccountGroup.id), isLoaded=\(selectedAccountGroup.isLoaded)")
                    }
                }
            let groupID = selectedAccountGroup.selectedAccountGroup.id

            // Балансировочный с showingRemainder < 0 — деньги пришли из ниоткуда (доход)
            let earningsAccounts = vm.accounts.filter { $0.type == .earnings || ($0.type == .balancing && $0.showingRemainder < 0) }
            AccountsTabView(
                vm: $vm,
                path: $path.path,
                accounts: earningsAccounts,
                accountType: .earnings,
                horizontalSpacing: horizontalSpacing,
                minRows: 1,
                maxRows: nil
            )
            .id("\(groupID)-\(vm.reloadToken)")
            .frame(height: 120)

            Divider()

            let regularAccounts = vm.accounts.filter { $0.type == .regular }
            AccountsTabView(
                vm: $vm,
                path: $path.path,
                accounts: regularAccounts,
                accountType: .regular,
                horizontalSpacing: horizontalSpacing,
                minRows: 1,
                maxRows: nil
            )
            .id("\(groupID)-\(vm.reloadToken)")
            .frame(height: 120)

            Divider()

            // Балансировочный с showingRemainder > 0 — деньги ушли в никуда (расход)
            let expenseAccounts = vm.accounts.filter { $0.type == .expense || ($0.type == .balancing && $0.showingRemainder > 0) }
            AccountsTabView(
                vm: $vm,
                path: $path.path,
                accounts: expenseAccounts,
                accountType: .expense,
                horizontalSpacing: horizontalSpacing,
                minRows: nil,
                maxRows: nil
            )
            .id("\(groupID)-\(vm.reloadToken)")
            .frame(maxHeight: .infinity)
            .frame(minHeight: 360)
        }
        // Долгий тап по ФОНУ экрана включает режим редактирования — как на Home Screen iOS, но
        // НЕ на самом кружке (тот уже пробовали — конкурирует за распознавание касания с
        // .draggable/ручным DragGesture кружка, см. DraggableAccountCircleItem). Кружки —
        // дочерние view со своими жестами и .contentShape(Circle()), они забирают касание
        // первыми в своих границах, так что этот жест реально срабатывает только там, где под
        // пальцем нет кружка (сама VStack, разделители, пустые ячейки сетки).
        //
        // Свой DragGesture(minimumDistance: 0) вместо .onLongPressGesture — тот на практике
        // срабатывал только по ОТПУСКАНИЮ пальца (конкурирует за распознавание с горизонтальными
        // ScrollView внутри AccountsTabView, и итог "кто победил" разрешался только когда палец
        // уже поднят), а нужно, чтобы режим включался ПРЯМО ВО ВРЕМЯ удержания — тот же паттерн
        // (Task.sleep + isCancelled), что уже используется в handleHoverExpand. .simultaneousGesture,
        // а не .gesture — чтобы не перехватывать touch у горизонтальных ScrollView строк.
        .contentShape(Rectangle())
        .simultaneousGesture(
            // .global — тем же coordinateSpace, что и registerCreateTransactionLocation, нужен
            // для сравнения координат в hasRegisteredAccount(near:) в onEnded ниже.
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    guard !vm.isEditMode else { return }

                    // Первое событие жеста (касание) — взводим таймер.
                    if editModeLongPressStart == nil {
                        editModeLongPressStart = value.startLocation
                        editModeLongPressMoved = false
                        editModeLongPressFired = false
                        editModeLongPressTask = Task {
                            try? await Task.sleep(for: .milliseconds(500))
                            // Не входим в режим, если: жест отменён; палец уже уехал (скролл/
                            // перелистывание — тоже держит палец >500мс, но двигается); или в
                            // это время идёт ручной драг счёта (.simultaneousGesture получает
                            // события параллельно с жестом кружка).
                            guard !Task.isCancelled, !editModeLongPressMoved, vm.draggableAccount == nil else { return }
                            editModeLongPressFired = true
                            withAnimation { vm.isEditMode = true }
                        }
                        return
                    }

                    // Палец поехал дальше системного slop'а (~10pt) — это скролл/перелистывание,
                    // а не удержание. Отменяем таймер и запоминаем, что было движение.
                    if let start = editModeLongPressStart,
                       hypot(value.location.x - start.x, value.location.y - start.y) > 10 {
                        editModeLongPressMoved = true
                        editModeLongPressTask?.cancel()
                        editModeLongPressTask = nil
                    }
                }
                .onEnded { value in
                    editModeLongPressTask?.cancel()
                    editModeLongPressTask = nil
                    let start = editModeLongPressStart
                    editModeLongPressStart = nil
                    let moved = editModeLongPressMoved || (start.map { hypot(value.location.x - $0.x, value.location.y - $0.y) > 10 } ?? false)

                    // Однократный тап (жест завершился раньше 500мс, без движения) по ФОНУ, пока
                    // режим редактирования уже включён, — выход из него. Долгое удержание уже само
                    // включило режим внутри onChanged. Если тап попал по кружку (а не по пустому
                    // фону) — выход не делаем: у кружка свой TapGesture, который в edit mode сам
                    // решает, что делать (открыть редактирование счёта), и делать это должен он,
                    // а не гаснуть isEditMode здесь ДО того, как отработает его обработчик.
                    if !editModeLongPressFired, !moved, vm.isEditMode, !vm.hasRegisteredAccount(near: value.location) {
                        withAnimation { vm.isEditMode = false }
                    }
                }
        )
        .contentMargins(.horizontal, horizontalSpacing, for: .scrollContent)
        .scrollIndicators(.hidden)
        // Плавающая панель дочерних счетов родителя (двойной тап, либо секундная задержка драга
        // над родителем) — в той же view-иерархии, что и основная сетка, поэтому дочерний счёт
        // можно перетащить отсюда на любой счёт основной сетки, в отличие от старого .popover.
        // Появляется на той же высоте, где был палец в момент открытия, либо по центру при
        // открытии двойным тапом. Слотов ДВА (primary/secondary) — оба ВСЕГДА в дереве (скрыты
        // opacity/allowsHitTesting, а не условным `if`): если тащат ребёнка ИЗ панели наружу, а
        // затем наводят на ДРУГОГО родителя, второй слот открывает ЕГО панель, не трогая первый —
        // тот продолжает держать живой view исходного ребёнка вместе с его DragGesture (иначе
        // жест обрывается и "призрак" замирает на месте — см. AccountCirclesViewModel.
        // ExpandedPanelSlot). account берём "липкий" — при первом скрытии показывать нечего,
        // используем последний известный, чтобы контент не дёргался на закрытии.
        .overlay {
            ExpandedChildrenPanel(
                vm: $vm,
                path: $path.path,
                slot: .primary,
                parentAccount: vm.primaryPanelAccount ?? Account(),
                anchorY: vm.primaryPanelAnchorY
            )
            .opacity(vm.primaryPanelVisible ? 1 : 0)
            .allowsHitTesting(vm.primaryPanelVisible)
            .animation(.default, value: vm.primaryPanelVisible)
        }
        .overlay {
            ExpandedChildrenPanel(
                vm: $vm,
                path: $path.path,
                slot: .secondary,
                parentAccount: vm.secondaryPanelAccount ?? Account(),
                anchorY: vm.secondaryPanelAnchorY
            )
            .opacity(vm.secondaryPanelVisible ? 1 : 0)
            .allowsHitTesting(vm.secondaryPanelVisible)
            .animation(.default, value: vm.secondaryPanelVisible)
        }
        // Призрак перетаскиваемого счёта для ручного драга (создание транзакции) — в отличие от
        // режима редактирования (там .draggable сам рисует системное превью), здесь его нужно
        // рисовать самим, раз это просто DragGesture. GeometryReader нужен, чтобы перевести
        // draggableLocation (глобальные координаты, из DragGesture(coordinateSpace: .global)) в
        // локальные координаты этого overlay — он сам не начинается в глобальном (0,0) (сверху
        // есть навбар/safe area). ВАЖНО: контейнер overlay'я должен быть растянут на весь VStack
        // (GeometryReader сам занимает весь предложенный размер) — иначе .overlay(alignment:
        // .center) даёт содержимому размер САМОГО СОДЕРЖИМОГО (тут — 60x60 круг), и .position()
        // начинает работать в этой крошечной локальной системе координат вместо координат всего
        // экрана (отсюда был баг "призрак прыгает из левого верхнего угла").
        .overlay {
            GeometryReader { proxy in
                if let draggableAccount = vm.draggableAccount, let draggableLocation = vm.draggableLocation {
                    let origin = proxy.frame(in: .global).origin
                    AccountCircleItemCircle(account: draggableAccount)
                        .frame(width: 60, height: 60)
                        .position(x: draggableLocation.x - origin.x, y: draggableLocation.y - origin.y)
                        .allowsHitTesting(false)
                }
            }
        }
        // Дебаг static locations (Developer Tools → "Показывать static locations") — точки на
        // месте каждой зарегистрированной позиции кружка, плюс индикатор момента первой
        // регистрации с момента появления/пересоздания экрана, чтобы сопоставить его с моментом,
        // когда счета визуально появились.
        .overlay {
            if debugShowStaticLocations {
                GeometryReader { proxy in
                    let origin = proxy.frame(in: .global).origin
                    ZStack(alignment: .top) {
                        ForEach(Array(vm.debugStaticLocations.keys), id: \.self) { accountID in
                            if let point = vm.debugStaticLocations[accountID] {
                                // Квадрат — реальная "зона действия" GeometryReader-регистрации
                                // (createTransactionTriggerZone по каждой оси), не просто точка:
                                // это и есть граница, в пределах которой ручной хит-тест сочтёт
                                // палец наведённым на этот счёт.
                                Rectangle()
                                    .strokeBorder(Color.orange, lineWidth: 1)
                                    .frame(
                                        width: vm.createTransactionTriggerZone * 2,
                                        height: vm.createTransactionTriggerZone * 2
                                    )
                                    .position(x: point.x - origin.x, y: point.y - origin.y)
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 6, height: 6)
                                    .position(x: point.x - origin.x, y: point.y - origin.y)
                            }
                        }
                        StaticLocationsDebugBadge(startedAt: vm.debugStaticLocationsStartedAt, count: vm.debugStaticLocations.count)
                            .padding(.top, 4)
                    }
                    .allowsHitTesting(false)
                }
            }
        }
            // Живая подписка на счета выбранной группы — .task(id:) сам переподписывается при
            // смене группы (замена старым .task/.onChange с ручным vm.load()). Нативный
            // drag-and-drop устойчив к тому, что accounts меняется во время самого перетаскивания
            // (в отличие от старой ручной системы), поэтому здесь больше не нужно ничего
            // пропускать на время драга.
            //
            // isLoaded в id — пока AccountGroupSelector не подгрузил реальную группу,
            // selectedAccountGroup.selectedAccountGroup — заглушка AccountGroup() из
            // AccountGroupSharedState.init(). Раньше .task стартовал сразу на этой заглушке
            // (полностью монтируя пустой TabView(.page)), а когда чуть позже прилетала настоящая
            // группа — id менялся, .task перезапускался, весь экран пересоздавался заново почти
            // сразу после первого маунта. Из-за этого TabView(.page) не успевал корректно
            // разложить свежевставленный контент (см. разбор бага с пропадающими static
            // locations) — экран монтировался дважды подряд вместо одного раза.
            .task(id: "\(selectedAccountGroup.selectedAccountGroup.id)-\(selectedAccountGroup.isLoaded)") {
                guard selectedAccountGroup.isLoaded else { return }
                let accountGroup = selectedAccountGroup.selectedAccountGroup
                vm.prepareForGroupSwitch(accountGroup)
                do {
                    for try await accounts in vm.observeAccounts(accountGroup: accountGroup) {
                        vm.applyObservedAccounts(accounts, for: accountGroup)
                    }
                } catch {
                    alert.error(error)
                }
            }
            // AccountCircleItemRoute/PlusNewAccountRoute/TransactionsListRoute/EditTransactionRoute/
            // TagsListRoute/ChartViewRoute уже зарегистрированы на NavigationStack в AccountCirclesTab
            // (этот экран — его root content, отдельного NavigationStack тут больше нет). Здесь
            // остаётся только DraggableAccountRoute — маршрут, специфичный для этого экрана.
            .navigationDestination(for: DraggableAccountRoute.self) { screen in
                switch screen {
                case .createTransaction(let transactionType, let accountFrom, let accountTo):
                    EditTransaction(
                        transactionType: transactionType,
                        accountFrom: accountFrom,
                        accountTo: accountTo,
                        accountGroup: selectedAccountGroup.selectedAccountGroup
                    )
                case .completeLinkedTransfer(let transactionType, let accountFrom, let accountTo, let transfer, let amount, let date, let note):
                    EditTransaction(
                        transactionType: transactionType,
                        accountFrom: accountFrom,
                        accountTo: accountTo,
                        accountGroup: accountFrom.accountGroup,
                        sourceTransfer: transfer,
                        prefillAmount: amount,
                        dateTransaction: date,
                        note: note
                    )
                }
            }
            .navigationDestination(for: PendingLinkedTransfersRoute.self) { screen in
                switch screen {
                case .list:
                    PendingLinkedTransfersList(accountGroup: selectedAccountGroup.selectedAccountGroup)
                case .completeLinkedTransfer(let transfer):
                    CompleteLinkedTransferPicker(transfer: transfer)
                }
            }
    }
}


#Preview {
    NavigationStack {
        AccountCirclesView()
            .environment(PathSharedState())
    }
    .environment(AlertManager(handle: {_ in }))
}
