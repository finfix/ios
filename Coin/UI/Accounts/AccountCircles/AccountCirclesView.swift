//
//  AccountCircleView.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI
import OSLog
import Factory

private let logger = Logger(subsystem: "Coin", category: "AccountCirclesView")

enum DraggableAccountRoute: Hashable {
case createTransaction(TransactionType, Account, Account)
case completeLinkedTransfer(TransactionType, Account, Account, PendingLinkedTransfer, Decimal, Date)
}

struct AccountsTabView: View {
    @Binding var vm: AccountCirclesViewModel
    @Binding var path: NavigationPath
    let accounts: [Account]
    let accountType: AccountType
    let horizontalSpacing: CGFloat
    let minRows: Int?
    let maxRows: Int?

    // Optional — того требует .scrollPosition(id:), которая заменила TabView(selection:).
    @State private var pageSelection: Int? = 0
    // Направление, в котором палец сейчас удерживается у края — используется, чтобы понять,
    // не сменился ли край (или перетаскивание не закончилось) с прошлого срабатывания таймера.
    @State private var edgePagingDirection: Int?
    @State private var edgePagingTimer: Timer?
    // Глобальный фрейм всей строки — нужен, чтобы во время РУЧНОГО драга (создание транзакции,
    // см. AccountCirclesViewModel.draggableLocation) самим сравнивать координату пальца с краями,
    // раз .dropDestination тут не сработает (тот получает координаты только от настоящих
    // системных drag-сессий, а ручной драг — обычный DragGesture).
    @State private var globalFrame: CGRect = .zero
    @AppStorage("debugShowStaticLocations") private var debugShowStaticLocations = false

    // Тонкая полоса у самого края экрана — сильно уже прежней (60pt), т.к. теперь это реальная
    // drop-зона поверх сетки: если сделать её широкой, она перехватывала бы дропы на кружки
    // ближнего к краю столбца. Достаточно, чтобы удержать палец за пределами обычной сетки.
    private let edgeZoneWidth: CGFloat = 24

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > 0 && geometry.size.height > 0 {
                let itemWidth: CGFloat = 80
                let itemHeight: CGFloat = 120

                let columnsCount = max(1, Int(geometry.size.width / (itemWidth + horizontalSpacing)))
                let rowsCount = if let minRows {
                    max(minRows, Int(geometry.size.height / itemHeight))
                } else if let maxRows {
                    min(maxRows, max(1, Int(geometry.size.height / itemHeight)))
                } else {
                    max(3, Int(geometry.size.height / itemHeight))
                }

                let itemsPerPage = columnsCount * rowsCount
                let pagesCount = max(1, Int(ceil(Double(accounts.count + 1) / Double(itemsPerPage))))

                let totalSpacing = geometry.size.width - (CGFloat(columnsCount) * itemWidth)
                let evenSpacing = totalSpacing / CGFloat(columnsCount + 1)

                ZStack {
                    // Заменили TabView(.page) (UIPageViewController под капотом) на чистый
                    // SwiftUI ScrollView + .scrollTargetBehavior(.paging) — доказано бисекцией,
                    // что именно TabView(.page) не завершал layout контента, вставленного уже
                    // после монтирования (см. разбор бага с пропадающими static locations).
                    // .containerRelativeFrame(.horizontal) даёт каждой странице ровно ширину
                    // контейнера — то самое центрирование, а .scrollPosition(id:) — замена
                    // pageSelection-бindинга TabView(selection:).
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 0) {
                            ForEach(0..<pagesCount, id: \.self) { pageIndex in
                                VStack {
                                    // Держим "тёплыми" только текущую и соседние страницы (как и
                                    // раньше) — LazyHStack и так не строит невидимые страницы
                                    // заранее, но эта проверка всё равно экономит сборку сетки
                                    // для дальних страниц, если они уже были построены раньше.
                                    if abs(pageIndex - (pageSelection ?? 0)) <= 1 {
                                        LazyVGrid(
                                            columns: Array(repeating: GridItem(.fixed(itemWidth), spacing: evenSpacing), count: columnsCount),
                                            spacing: horizontalSpacing
                                        ) {
                                            let startIndex = pageIndex * itemsPerPage
                                            let endIndex = min(startIndex + itemsPerPage, accounts.count)
                                            let pageAccounts = Array(accounts[startIndex..<endIndex])

                                            ForEach(pageAccounts) { account in
                                                DraggableAccountCircleItem(vm: $vm, account: account, path: $path)
                                            }

                                            if pageIndex == pagesCount - 1 {
                                                PlusNewAccount(accountType: accountType)
                                            }
                                        }
                                    } else {
                                        Color.clear
                                            .frame(height: CGFloat(rowsCount) * itemHeight)
                                    }
                                    Spacer()
                                }
                                .containerRelativeFrame(.horizontal)
                                .id(pageIndex)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $pageSelection)
                    .scrollIndicators(.hidden)
                    .onChange(of: pagesCount) { _, newValue in
                        pageSelection = min(pageSelection ?? 0, newValue - 1)
                    }
                    .onChange(of: pageSelection) { _, _ in
                        vm.geometryRefreshTrigger += 1
                    }

                    // Перетаскиваемый счёт может понадобиться уронить на счёт с другой "страницы"
                    // пейджинга — держим палец у одного из этих тонких краёв, страница листается
                    // сама, пока палец не уйдёт от края или перетаскивание не закончится. В
                    // отличие от старой версии (полагалась на ручной трекинг координат пальца),
                    // это настоящие drop-зоны — сама система сообщает, что палец сейчас над ними.
                    HStack(spacing: 0) {
                        edgeDropZone(direction: -1, pagesCount: pagesCount)
                            .frame(width: edgeZoneWidth)
                        Spacer()
                        edgeDropZone(direction: 1, pagesCount: pagesCount)
                            .frame(width: edgeZoneWidth)
                    }
                }
                .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { newValue in
                    globalFrame = newValue
                }
                .onChange(of: vm.draggableLocation) { _, newLocation in
                    updateManualEdgePaging(location: newLocation, pagesCount: pagesCount)
                }
                // Граница GeometryReader самого AccountsTabView (задаёт columns/rows/pages и
                // globalFrame для авто-листания) — раз она занимает весь geometry.size, в
                // локальных координатах это просто рамка вокруг всей строки.
                .overlay {
                    if debugShowStaticLocations {
                        Rectangle()
                            .strokeBorder(Color.blue, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .allowsHitTesting(false)
                    }
                }
            } else {
                Color.clear
            }
        }
    }

    private func edgeDropZone(direction: Int, pagesCount: Int) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .dropDestination(for: DraggedAccount.self) { _, _ in false } isTargeted: { targeted in
                if targeted {
                    startEdgePaging(direction: direction, pagesCount: pagesCount)
                } else if edgePagingDirection == direction {
                    stopEdgePaging()
                }
            }
    }

    // Аналог edgeDropZone(isTargeted:), но для ручного драга (создание транзакции) — там нет
    // настоящей drag-сессии, поэтому просто сравниваем координату пальца с краями своего фрейма.
    //
    // vm.draggableLocation — общее состояние на весь экран, и ВСЕ AccountsTabView (earnings/
    // regular/expense) слушают его одновременно, независимо от того, видна ли сейчас эта
    // конкретная строка. Если открыта панель дочерних счетов (vm.expandedParentAccount != nil) и
    // x пальца случайно попадает в edge-зону строки, СКРЫТОЙ за панелью, та начинала листать
    // страницы вслепую (кружки скрытой строки регистрировали новые позиции, хотя палец
    // физически двигался только по панели) — отсюда и нестабильное поведение панели. Пока
    // панель открыта, авто-листание краёв полностью отключено: тащить между страницами имеет
    // смысл только когда панель закрыта и видна сама сетка.
    private func updateManualEdgePaging(location: CGPoint?, pagesCount: Int) {
        guard let location, globalFrame != .zero, vm.expandedParentAccount == nil else {
            if edgePagingDirection != nil {
                stopEdgePaging()
            }
            return
        }
        if location.x < globalFrame.minX + edgeZoneWidth {
            startEdgePaging(direction: -1, pagesCount: pagesCount)
        } else if location.x > globalFrame.maxX - edgeZoneWidth {
            startEdgePaging(direction: 1, pagesCount: pagesCount)
        } else if edgePagingDirection != nil {
            stopEdgePaging()
        }
    }

    private func startEdgePaging(direction: Int, pagesCount: Int) {
        guard edgePagingDirection != direction else { return }
        edgePagingDirection = direction
        edgePagingTimer?.invalidate()
        edgePagingTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { _ in
            Task { @MainActor in
                let nextPage = (pageSelection ?? 0) + direction
                guard nextPage >= 0 && nextPage < pagesCount else { return }
                withAnimation {
                    pageSelection = nextPage
                }
            }
        }
    }

    private func stopEdgePaging() {
        edgePagingDirection = nil
        edgePagingTimer?.invalidate()
        edgePagingTimer = nil
    }
}

/// Плавающая панель дочерних счетов — см. AccountCirclesViewModel.expandedParentAccount.
struct ExpandedChildrenPanel: View {
    @Binding var vm: AccountCirclesViewModel
    @Binding var path: NavigationPath
    let parentAccount: Account
    let anchorY: CGFloat?

    // Временный визуальный дебаг закрытия панели (Developer Tools → тумблер) — рисует границу
    // panelGlobalFrame и точку draggableLocation прямо на экране, плюс логирует в консоль каждое
    // срабатывание закрытия и его причину, чтобы понять, почему панель закрывается "как будто
    // сама по себе".
    @AppStorage("debugPanelClose") private var debugPanelClose = false

    // Небольшая задержка перед тем, как задник панели начинает закрывать её при наведении —
    // без неё панель закрывалась бы сама в момент открытия: палец в этот момент ещё стоит там
    // же, где был родитель в основной сетке, а эта точка теперь накрыта задником (он поверх
    // всего), и задник немедленно посчитал бы это "вышли за пределы панели".
    @State private var backdropCanClose = false
    // Размер самой карточки панели (ДО .padding/.position) — из него в body аналитически
    // вычисляется panelGlobalFrame. Раньше пытались измерить итоговый глобальный фрейм через
    // .onGeometryChange, повешенный ПОСЛЕ .position(x:y:) — но .position() превращает view в
    // "невидимую рамку на весь доступный размер" для целей layout, и GeometryReader после него
    // всегда мерил эту невидимую полноразмерную рамку (весь экран), а не реальный размер
    // карточки — отсюда и был баг "красная зона на весь экран, включая хэдер".
    @State private var cardSize: CGSize = .zero

    private func close(reason: String, panelGlobalFrame: CGRect) {
        if debugPanelClose {
            logger.debug("ExpandedChildrenPanel closing: \(reason) — panelGlobalFrame=\(String(describing: panelGlobalFrame)) draggableLocation=\(String(describing: vm.draggableLocation)) backdropCanClose=\(backdropCanClose)")
        }
        withAnimation { vm.closeExpandedPanel() }
    }

    var body: some View {
        GeometryReader { proxy in
            let overlayOriginY = proxy.frame(in: .global).minY
            let overlayOriginX = proxy.frame(in: .global).minX
            let localY = (anchorY ?? proxy.frame(in: .global).midY) - overlayOriginY
            let clampedY = min(max(localY, 80), proxy.size.height - 80)
            // Аналитический расчёт вместо измерения через GeometryReader ПОСЛЕ .position() —
            // см. комментарий у cardSize. Мы сами знаем формулу центрирования (x: центр экрана,
            // y: clampedY), поэтому просто подставляем размер карточки (cardSize, измеренный ДО
            // .position()) в неё.
            let panelGlobalFrame = CGRect(
                x: proxy.size.width / 2 - cardSize.width / 2 + overlayOriginX,
                y: clampedY - cardSize.height / 2 + overlayOriginY,
                width: cardSize.width,
                height: cardSize.height
            )

            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    close(reason: "tap on backdrop", panelGlobalFrame: panelGlobalFrame)
                }
                // Задник "выигрывает" hit-test везде, кроме самих дочерних кружков (они рисуются
                // поверх и хватают события первыми) — значит, если задник стал targeted, палец
                // сейчас вне панели (в т.ч. в пустых промежутках между кружками), и панель нужно
                // закрыть — ровно то самое "вышел за пределы панели".
                .dropDestination(for: DraggedAccount.self) { _, _ in false } isTargeted: { targeted in
                    guard targeted, backdropCanClose else { return }
                    close(reason: "native dropDestination targeted backdrop", panelGlobalFrame: panelGlobalFrame)
                }
                .task(id: parentAccount.id) {
                    backdropCanClose = false
                    try? await Task.sleep(for: .milliseconds(400))
                    backdropCanClose = true
                }
                .onChange(of: vm.draggableLocation) { _, newLocation in
                    guard backdropCanClose, let newLocation, panelGlobalFrame != .zero,
                          !panelGlobalFrame.contains(newLocation) else { return }
                    close(reason: "manual draggableLocation outside panelGlobalFrame", panelGlobalFrame: panelGlobalFrame)
                }
                .overlay {
                    if debugPanelClose {
                        Rectangle()
                            .strokeBorder(Color.red, lineWidth: 2)
                            .frame(width: panelGlobalFrame.width, height: panelGlobalFrame.height)
                            .position(
                                x: panelGlobalFrame.midX - overlayOriginX,
                                y: panelGlobalFrame.midY - overlayOriginY
                            )
                            .allowsHitTesting(false)
                        // Точные числа panelGlobalFrame прямо на экране — чтобы не гадать по
                        // виду рамки, а видеть, что реально захватывается.
                        Text("panelGlobalFrame: \(String(describing: panelGlobalFrame))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.red)
                            .position(x: proxy.size.width / 2, y: 100)
                            .allowsHitTesting(false)
                        if let draggableLocation = vm.draggableLocation {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 14, height: 14)
                                .position(
                                    x: draggableLocation.x - overlayOriginX,
                                    y: draggableLocation.y - overlayOriginY
                                )
                                .allowsHitTesting(false)
                        }
                    }
                }
                .overlay {
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(parentAccount.childrenAccounts) { child in
                                DraggableAccountCircleItem(
                                    vm: $vm,
                                    account: child,
                                    path: $path,
                                    isAlreadyOpened: true
                                )
                                .frame(width: 80)
                            }
                        }
                        .padding()
                    }
                    .frame(height: 140)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                    // Измеряем размер карточки ЗДЕСЬ — до .position(). GeometryReader/
                    // onGeometryChange, повешенный ПОСЛЕ .position(x:y:), мерил бы не реальный
                    // размер карточки, а "невидимую рамку на весь доступный размер", в которую
                    // .position() оборачивает view для целей layout (отсюда был баг "красная зона
                    // на весь экран, включая хэдер" — раньше onGeometryChange стоял после
                    // .position()).
                    .background {
                        GeometryReader { cardProxy in
                            Color.clear
                                .onAppear { cardSize = cardProxy.size }
                                .onChange(of: cardProxy.size) { _, newValue in
                                    cardSize = newValue
                                }
                        }
                    }
                    .position(
                        x: proxy.size.width / 2,
                        y: clampedY
                    )
                }
        }
    }
}

struct AccountCirclesView: View {
    
    @Environment(AlertManager.self) private var alert
    @Environment(AccountGroupSharedState.self) private var selectedAccountGroup
    // Не свой NavigationStack — этот экран всегда встроен в NavigationStack, который уже создаёт
    // AccountCirclesTab (вложенный NavigationStack внутри другого приводил к неустойчивым багам
    // с навигацией — экраны копились в стеке, dismiss возвращал не туда).
    @Environment(PathSharedState.self) private var path
    @State private var vm = AccountCirclesViewModel()
    @AppStorage("debugShowStaticLocations") private var debugShowStaticLocations = false

    let horizontalSpacing: CGFloat = 10

    var body: some View {
        @Bindable var path = path
        VStack {
            QuickStatisticView(selectedAccountGroup: selectedAccountGroup.selectedAccountGroup)
                .onAppear {
                    if debugShowStaticLocations {
                        logger.debug("AccountCirclesView.body: (пере)появился — id=\(String(describing: ObjectIdentifier(vm))), isLogin=\(AuthStorage.shared.isLogin), selectedGroup=\(selectedAccountGroup.selectedAccountGroup.id), isLoaded=\(selectedAccountGroup.isLoaded)")
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
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.5) {
            guard !vm.isEditMode else { return }
            withAnimation { vm.isEditMode = true }
        }
        .contentMargins(.horizontal, horizontalSpacing, for: .scrollContent)
        .scrollIndicators(.hidden)
        // Плавающая панель дочерних счетов родителя (двойной тап, либо секундная задержка драга
        // над родителем) — в той же view-иерархии, что и основная сетка, поэтому дочерний счёт
        // можно перетащить отсюда на любой счёт основной сетки, в отличие от старого .popover.
        // Появляется на той же высоте, где был палец в момент открытия (expandedParentAccountAnchorY),
        // либо по центру при открытии двойным тапом.
        .overlay {
            if let expandedParentAccount = vm.expandedParentAccount {
                ExpandedChildrenPanel(
                    vm: $vm,
                    path: $path.path,
                    parentAccount: expandedParentAccount,
                    anchorY: vm.expandedParentAccountAnchorY
                )
                .transition(.opacity)
            }
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
                case .completeLinkedTransfer(let transactionType, let accountFrom, let accountTo, let transfer, let amount, let date):
                    EditTransaction(
                        transactionType: transactionType,
                        accountFrom: accountFrom,
                        accountTo: accountTo,
                        accountGroup: accountFrom.accountGroup,
                        sourceTransfer: transfer,
                        prefillAmount: amount,
                        dateTransaction: date
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
            .toolbar {
                if !vm.isEditMode {
                    ToolbarItem(placement: .navigationBarLeading) {
                        // .id(...) — иначе @State vm внутри PendingLinkedTransfersBadge
                        // инициализируется один раз при первом маунте тулбара и навсегда
                        // застревает с той группой, что была на тот момент (в т.ч. с
                        // заглушкой AccountGroup(), пока реальная группа ещё не подгрузилась —
                        // см. .task(id:) ниже с тем же isLoaded-гейтом). .id() форсирует
                        // пересоздание view (и его @State) при смене реальной группы.
                        PendingLinkedTransfersBadge(accountGroup: selectedAccountGroup.selectedAccountGroup)
                            .id(selectedAccountGroup.selectedAccountGroup.id)
                    }
                }
                // Вход в режим редактирования — долгим тапом по любому кружку (см.
                // DraggableAccountCircleItem.LongPressToEditIf), как на Home Screen iOS. Кнопка
                // осталась только для выхода — "Готово" симметрично понятнее свайпа/тапа мимо.
                if vm.isEditMode {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Готово") {
                            withAnimation {
                                vm.isEditMode = false
                            }
                        }
                    }
                }
            }
    }
}

/// Индикатор для дебага static locations — показывает момент первой регистрации позиции с
/// момента появления/пересоздания экрана и живой "прошло N мс с этого момента", чтобы можно было
/// на глаз сопоставить его с моментом, когда счета визуально появились (см. отчёт про баг
/// "static locations иногда не регистрируются при первом появлении экрана").
private struct StaticLocationsDebugBadge: View {
    let startedAt: Date?
    let count: Int

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.05)) { context in
            HStack(spacing: 6) {
                Circle()
                    .fill(startedAt == nil ? Color.red : Color.green)
                    .frame(width: 8, height: 8)
                if let startedAt {
                    Text("static locations: старт \(Self.timeFormatter.string(from: startedAt)), +\(Int(context.date.timeIntervalSince(startedAt) * 1000))мс, зарегистрировано \(count)")
                } else {
                    Text("static locations: ещё ни одной регистрации")
                }
            }
            .font(.caption2.monospaced())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.7), in: Capsule())
            .foregroundColor(.white)
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
