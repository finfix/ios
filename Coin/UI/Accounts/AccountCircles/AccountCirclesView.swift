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
}

struct AccountsTabView: View {
    @Binding var vm: AccountCirclesViewModel
    @Binding var path: NavigationPath
    let accountGroup: AccountGroup
    let accounts: [Account]
    let accountType: AccountType
    let horizontalSpacing: CGFloat
    let minRows: Int?
    let maxRows: Int?

    @State private var pageSelection = 0
    // Направление, в котором палец сейчас удерживается у края — используется, чтобы понять,
    // не сменился ли край (или перетаскивание не закончилось) с прошлого срабатывания таймера.
    @State private var edgePagingDirection: Int?
    @State private var edgePagingTimer: Timer?

    // Насколько близко к краю экрана (а не этого конкретного view — TabView и так на всю
    // ширину) нужно удерживать перетаскиваемый счёт, чтобы запустить перелистывание.
    private let edgeZoneWidth: CGFloat = 60

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

                TabView(selection: $pageSelection) {
                    ForEach(0..<pagesCount, id: \.self) { pageIndex in
                        VStack {
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.fixed(itemWidth), spacing: evenSpacing), count: columnsCount),
                                spacing: horizontalSpacing
                            ) {
                                let startIndex = pageIndex * itemsPerPage
                                let endIndex = min(startIndex + itemsPerPage, accounts.count)
                                let pageAccounts = Array(accounts[startIndex..<endIndex])
                                let displayedAccounts = liveReorderedAccounts(pageAccounts, itemsPerPage: itemsPerPage)

                                ForEach(displayedAccounts) { account in
                                    DraggableAccountCircleItem(vm: $vm, accountGroup: accountGroup, account: account, path: $path)
                                }
                                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: displayedAccounts.map(\.id))

                                if pageIndex == pagesCount - 1 {
                                    PlusNewAccount(accountType: accountType)
                                }
                            }
                            Spacer()
                        }
                        .tag(pageIndex)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: vm.draggableLocation) { _, newLocation in
                    handleEdgeAutoPaging(location: newLocation, pagesCount: pagesCount)
                }
                .onChange(of: vm.reorderDraggableLocation) { _, newLocation in
                    handleEdgeAutoPaging(location: newLocation, pagesCount: pagesCount)
                }
                .onChange(of: pagesCount) { _, newValue in
                    pageSelection = min(pageSelection, newValue - 1)
                }
            } else {
                Color.clear
            }
        }
    }

    // Живой предпросмотр перестановки: пока счёт перетаскивается внутри этой же страницы,
    // остальные кружки визуально "расступаются" — переставляем перетаскиваемый счёт рядом
    // с текущей целью в том же массиве, который рендерит сетка. Как только меняется порядок,
    // ForEach (см. .animation(value: displayedAccounts.map(\.id)) выше) сам анимирует сдвиг.
    // Сам перетаскиваемый кружок в этом массиве остаётся (чтобы сетка не схлопывалась), но
    // визуально скрыт (opacity 0 в DraggableAccountCircleItem) — на экране вместо него летит
    // отдельный "призрак" под пальцем (см. AccountCirclesView).
    private func liveReorderedAccounts(_ pageAccounts: [Account], itemsPerPage: Int) -> [Account] {
        guard vm.isEditMode,
              let dragged = vm.reorderDraggableAccount,
              dragged.type == accountType,
              let target = vm.reorderTargetAccount,
              dragged.id != target.id,
              let originalTargetIndex = pageAccounts.firstIndex(where: { $0.id == target.id }) else {
            return pageAccounts
        }

        var result = pageAccounts
        // Перетаскиваемый счёт может быть с ДРУГОЙ страницы — например, после автолистания
        // краем экрана во время перестановки. В этом случае его просто нет в pageAccounts,
        // и его нужно не убирать, а сразу "вставить", подвинув счета этой страницы.
        let draggedIndexOnThisPage = result.firstIndex(where: { $0.id == dragged.id })
        let movingForward: Bool
        if let draggedIndexOnThisPage {
            movingForward = draggedIndexOnThisPage < originalTargetIndex
            result.remove(at: draggedIndexOnThisPage)
        } else {
            let sameTypeSorted = vm.accounts.filter { $0.type == accountType }.sorted { $0.rank < $1.rank }
            let draggedGlobalIndex = sameTypeSorted.firstIndex(where: { $0.id == dragged.id }) ?? 0
            let targetGlobalIndex = sameTypeSorted.firstIndex(where: { $0.id == target.id }) ?? 0
            movingForward = draggedGlobalIndex < targetGlobalIndex
        }

        guard let targetIndexAfterRemoval = result.firstIndex(where: { $0.id == target.id }) else {
            return pageAccounts
        }
        let insertIndex = movingForward ? targetIndexAfterRemoval + 1 : targetIndexAfterRemoval
        result.insert(dragged, at: min(insertIndex, result.count))

        // Вставка счёта с другой страницы может раздуть массив сверх itemsPerPage — тогда
        // LazyVGrid просто заворачивает лишний элемент на вторую строку (особенно заметно
        // в однорядных секциях вроде "Доходы"). Нужно, чтобы последний счёт вместо этого
        // "убегал" за пределы страницы, поэтому обрезаем до итогового лимита.
        if result.count > itemsPerPage {
            result.removeLast(result.count - itemsPerPage)
        }
        return result
    }

    // Какие типы счетов вообще можно принять как цель для текущего перетаскиваемого счёта —
    // см. правила в AccountCirclesViewModel.updateDraggableLocation (earnings→regular,
    // regular→regular/expense). Листать нужно только тот уровень, куда действительно можно
    // уронить — иначе при переносе с "Доходов" на "Обычные" одновременно листались бы и
    // "Расходы", хотя туда доходный счёт всё равно уронить нельзя.
    private func isValidDropTargetRow(for draggableAccountType: AccountType) -> Bool {
        switch draggableAccountType {
        case .earnings: accountType == .regular
        case .regular: accountType == .regular || accountType == .expense
        case .expense, .debt, .balancing: false
        }
    }

    // Перетаскиваемый счёт может понадобиться уронить на счёт с другой "страницы" пейджинга —
    // без этого механизма перетаскивание работало только внутри одной видимой страницы, т.к.
    // позиции счетов с других страниц (staticLocations) не регистрируются, пока страница не
    // показана. Держим палец у края экрана — через паузу страница листается, и так повторно,
    // пока палец не уйдёт от края или перетаскивание не закончится.
    private func handleEdgeAutoPaging(location: CGPoint?, pagesCount: Int) {
        // Тот же механизм нужен и для перестановки счетов местами (режим редактирования) —
        // там своп разрешён только внутри одной секции, поэтому листаем только ту страницу,
        // чей accountType совпадает с типом перетаскиваемого счёта.
        let isValidRow: Bool
        if let reorderAccount = vm.reorderDraggableAccount {
            isValidRow = reorderAccount.type == accountType
        } else if let draggableAccount = vm.draggableAccount {
            isValidRow = isValidDropTargetRow(for: draggableAccount.type)
        } else {
            isValidRow = false
        }
        guard let location, isValidRow else {
            stopEdgePaging()
            return
        }
        let screenWidth = UIScreen.main.bounds.width
        let direction: Int?
        if location.x < edgeZoneWidth {
            direction = -1
        } else if location.x > screenWidth - edgeZoneWidth {
            direction = 1
        } else {
            direction = nil
        }

        guard let direction else {
            stopEdgePaging()
            return
        }
        guard direction != edgePagingDirection else { return }

        edgePagingDirection = direction
        edgePagingTimer?.invalidate()
        edgePagingTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { _ in
            Task { @MainActor in
                let nextPage = pageSelection + direction
                guard nextPage >= 0 && nextPage < pagesCount else { return }
                withAnimation {
                    pageSelection = nextPage
                }
                // Цель при перестановке ищется по замороженному снимку (см.
                // AccountCirclesViewModel) — после перелистывания нужно подмешать в него
                // позиции только что появившихся там счетов, иначе отпустить перетаскиваемый
                // счёт на них будет невозможно. Ждём, пока новая страница отрисуется и
                // зарегистрирует свои позиции через GeometryReader/preference.
                if vm.reorderDraggableAccount != nil {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    vm.mergeIntoReorderReferenceLocations()
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

struct CoordinateGrid: View {
    let spacing: CGFloat = 10
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Вертикальные линии
            ForEach(0...Int(size.width/spacing), id: \.self) { i in
                let x = CGFloat(i) * spacing
                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                .stroke(Color.blue.opacity(0.2), lineWidth: 0.5)
                
                // Метки по X каждые 50 пикселей
                if i % 5 == 0 {
                    Text("\(Int(x))")
                        .font(.system(size: 8))
                        .position(x: x, y: 10)
                }
            }
            
            // Горизонтальные линии
            ForEach(0...Int(size.height/spacing), id: \.self) { i in
                let y = CGFloat(i) * spacing
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                .stroke(Color.blue.opacity(0.2), lineWidth: 0.5)
                
                // Метки по Y каждые 50 пикселей
                if i % 5 == 0 {
                    Text("\(Int(y))")
                        .font(.system(size: 8))
                        .position(x: 10, y: y)
                }
            }
        }
    }
}

struct AccountCirclesView: View {
    
    @Environment(AlertManager.self) private var alert
    @Environment(AccountGroupSharedState.self) private var selectedAccountGroup
    @State private var path = PathSharedState()
    @State private var vm = AccountCirclesViewModel()
    @State private var quickStatisticVM = QuickStatisticViewModel()
    @State private var dragLocation: CGPoint?
    @AppStorage("debugShowStaticLocations") private var debugShowStaticLocations = false
    
    let horizontalSpacing: CGFloat = 10
    
    var body: some View {
        NavigationStack(path: $path.path) {
            GeometryReader { geometry in
                ZStack {
                    VStack {
                        QuickStatisticView(selectedAccountGroup: selectedAccountGroup.selectedAccountGroup)
                        
                        let groupID = selectedAccountGroup.selectedAccountGroup.id

                        // Балансировочный с showingRemainder < 0 — деньги пришли из ниоткуда (доход)
                        let earningsAccounts = vm.accounts.filter { $0.type == .earnings || ($0.type == .balancing && $0.showingRemainder < 0) }
                        AccountsTabView(
                            vm: $vm,
                            path: $path.path,
                            accountGroup: selectedAccountGroup.selectedAccountGroup,
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
                            accountGroup: selectedAccountGroup.selectedAccountGroup,
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
                            accountGroup: selectedAccountGroup.selectedAccountGroup,
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
                    .contentMargins(.horizontal, horizontalSpacing, for: .scrollContent)
                    .scrollIndicators(.hidden)
                    
                    if debugShowStaticLocations {
                        // Читаем снимок staticLocations при каждом рендере (vm.accounts — наблюдаемый триггер)
                        let _ = vm.accounts
                        let allAccounts = vm.accounts.flatMap { [$0] + $0.childrenAccounts }
                        ForEach(Array(vm.staticLocations.keys), id: \.self) { accountID in
                            if let point = vm.staticLocations[accountID] {
                                let name = allAccounts.first(where: { $0.id == accountID })?.name ?? accountID.uuidString.prefix(8).description
                                // Зелёный — сейчас это reorderTargetAccount (то, с кем реально
                                // произойдёт своп при отпускании), синий — сам перетаскиваемый
                                // счёт (его позиция уже не актуальна, кружок скрыт), красный —
                                // все остальные зарегистрированные позиции.
                                let isTarget = vm.reorderTargetAccount?.id == accountID
                                let isDragged = vm.reorderDraggableAccount?.id == accountID
                                let markerColor: Color = isTarget ? .green : (isDragged ? .blue : .red)
                                ZStack {
                                    Circle()
                                        .fill(markerColor.opacity(0.35))
                                        .frame(width: 60, height: 60)
                                    Circle()
                                        .strokeBorder(markerColor, lineWidth: isTarget ? 3 : 1)
                                        .frame(width: 60, height: 60)
                                    Text(name)
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 56)
                                }
                                .position(CGPoint(
                                    x: point.x,
                                    y: point.y - geometry.safeAreaInsets.top
                                ))
                                .allowsHitTesting(false)
                            }
                        }

                        // Радиус, в котором вообще ищутся кандидаты на цель (triggerZone) —
                        // рисуется вокруг текущей позиции пальца при перестановке.
                        if let reorderLocation = vm.reorderDraggableLocation {
                            Circle()
                                .strokeBorder(Color.yellow.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                .frame(width: vm.triggerZone * 2, height: vm.triggerZone * 2)
                                .position(CGPoint(
                                    x: reorderLocation.x,
                                    y: reorderLocation.y - geometry.safeAreaInsets.top
                                ))
                                .allowsHitTesting(false)
                        }

                        // Точка, где система СЕЙЧАС считает палец при перестановке — сверяем
                        // с местом реального (visible) призрака-кружка ниже. Если они всегда
                        // совпадают в момент отрисовки, значит "перемещается через одну" — не
                        // про рассинхрон местоположения самого пальца, а про то, что onChanged
                        // у DragGesture в принципе не гарантирует событие на КАЖДЫЙ пиксель
                        // движения (шлёт с частотой сэмплирования тача, обычно ~60–120 Гц, но
                        // не более одного события за кадр рендера) — на глаз можно решить, что
                        // "прыгает через раз", хотя на деле рисуется каждое полученное значение.
                        if let reorderLocation = vm.reorderDraggableLocation {
                            ZStack {
                                Circle()
                                    .fill(Color.cyan.opacity(0.5))
                                    .frame(width: 40, height: 40)
                                Text("👻")
                                    .font(.system(size: 16))
                            }
                            .position(CGPoint(
                                x: reorderLocation.x,
                                y: reorderLocation.y - geometry.safeAreaInsets.top
                            ))
                            .allowsHitTesting(false)
                        }

                        // Табличка с числами последней итерации updateReorderDraggableLocation,
                        // плавающая прямо НАД пальцем (а не в фиксированном месте экрана) —
                        // чтобы не приходилось переводить взгляд туда-сюда между пальцем и HUD.
                        // Показывает: лучший кандидат сейчас и расстояние до него, прежняя цель
                        // и расстояние до неё, порог гистерезиса, и сменилась ли цель именно
                        // в этом кадре.
                        if let reorderLocation = vm.reorderDraggableLocation, let snapshot = vm.reorderDebugSnapshot {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("best: \(snapshot.bestCandidateName ?? "—")  \(snapshot.bestCandidateDistance.map { String(format: "%.0f", $0) } ?? "—")pt")
                                Text("target: \(snapshot.currentTargetName ?? "—")  \(snapshot.currentTargetDistance.map { String(format: "%.0f", $0) } ?? "—")pt")
                                Text("hysteresis: \(Int(vm.reorderHysteresis))pt · zone: \(Int(vm.triggerZone))pt")
                                if snapshot.targetChanged {
                                    Text("→ ЦЕЛЬ СМЕНИЛАСЬ")
                                        .foregroundStyle(.yellow)
                                }
                            }
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 6))
                            .fixedSize()
                            .position(CGPoint(
                                x: min(max(reorderLocation.x, 90), geometry.size.width - 90),
                                y: reorderLocation.y - geometry.safeAreaInsets.top - 70
                            ))
                            .allowsHitTesting(false)
                        }
                    }

                    if let draggableLocation = vm.draggableLocation {
                        Circle()
                            .fill(.orange)
                            .frame(width: 70, height: 70)
                            .shadow(radius: 10)
                            .overlay {
                                if let draggableAccount = vm.draggableAccount {
                                        AsyncImage(url: URL.documentsDirectory.appending(path: draggableAccount.icon.url)) { image in
                                            image.image?
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 50)
                                        }
                                    }
                            }
                            .position(CGPoint(
                                x: draggableLocation.x,
                                y: draggableLocation.y - geometry.safeAreaInsets.top
                            ))
                    }

                    // "Призрак" перетаскиваемого в режиме редактирования счёта — летит прямо
                    // за пальцем, пока сетка под ним (см. liveReorderedAccounts) уже показывает,
                    // куда он встанет после отпускания.
                    if let reorderLocation = vm.reorderDraggableLocation, let reorderAccount = vm.reorderDraggableAccount {
                        // AccountCircleItemCircle сама фиксирует только высоту (60) — обычно её
                        // ширину неявно задаёт containing VStack(width: 80). Если тут задать
                        // несимметричный внешний .frame (например, 70x70), внутренняя
                        // Circle().frame(height: 60) получает предложение по ширине от НАШЕГО
                        // фрейма и рисуется овалом (70×60), а не кругом — отсюда видимое
                        // смещение "мимо пальца". Даём квадратный фрейм, совпадающий с её
                        // реальным диаметром.
                        AccountCircleItemCircle(account: reorderAccount)
                            .frame(width: 60, height: 60)
                            .scaleEffect(1.15)
                            .shadow(color: .black.opacity(0.35), radius: 10)
                            .position(CGPoint(
                                x: reorderLocation.x,
                                y: reorderLocation.y - geometry.safeAreaInsets.top
                            ))
                            // Позиция призрака всегда должна прыгать мгновенно вслед за пальцем —
                            // без этого она наследует ambient-анимацию от withAnimation вокруг
                            // смены pageSelection при автолистании и на время слайда страницы
                            // визуально "отстаёт" от реального пальца, догоняя только к концу
                            // анимации перехода.
                            .animation(nil, value: reorderLocation)
                            .allowsHitTesting(false)
                    }
                }
            }
            .task {
                vm.draggableLocation = nil
                do {
                    try await vm.load(accountGroup: selectedAccountGroup.selectedAccountGroup)
                    try await quickStatisticVM.load()
                } catch {
                    alert.error(error)
                }
            }
            .onChange(of: selectedAccountGroup.selectedAccountGroup) { _, newValue in
                Task {
                    do {
                        try await vm.load(accountGroup: selectedAccountGroup.selectedAccountGroup)
                        try await quickStatisticVM.load()
                    } catch {
                        alert.error(error)
                    }
                }
            }
            .navigationDestination(for: AccountCircleItemRoute.self) { screen in
                switch screen {
                case .accountTransactions(let account, let chartType): TransactionsView(
                    filters: TransactionFilters(
                        accounts: [account],
                        accountGroups: [account.accountGroup]
                    ),
                    chartType: chartType)
                case .editAccount(let account): EditAccount(account, selectedAccountGroup: selectedAccountGroup.selectedAccountGroup, isHiddenView: false)
                }
            }
            .navigationDestination(for: PlusNewAccountRoute.self) { screen in
                switch screen {
                case .createAccount(let accountType): EditAccount(accountType: accountType, accountGroup: selectedAccountGroup.selectedAccountGroup)
                }
            }
            .navigationDestination(for: TransactionsListRoute.self) { screen in
                switch screen {
                case .editTransaction(let transaction): EditTransaction(transaction)
                }
            }
            .navigationDestination(for: EditTransactionRoute.self) { screen in
                switch screen {
                case .tagsList:
                    TagsList(accountGroup: selectedAccountGroup.selectedAccountGroup)
                case .auditLogHistory(let entityID, let accountGroupID):
                    AuditLogHistoryView(entity: .transaction, entityID: entityID, accountGroupID: accountGroupID)
                }
            }
            .navigationDestination(for: TagsListRoute.self) { screen in
                switch screen {
                case .createTag:
                    EditTag(selectedAccountGroup: selectedAccountGroup.selectedAccountGroup)
                case .editTag(let tag):
                    EditTag(tag)
                }
            }
            .navigationDestination(for: ChartViewRoute.self) { screen in
                switch screen {
                case .transactionView(let filters, let chartType):
                    TransactionsView(filters: filters, chartType: chartType)
                case .chartDrillDown(let filters, let chartType):
                    TransactionsView(filters: filters, chartType: chartType)
                }
            }
            .navigationDestination(for: DraggableAccountRoute.self) { screen in
                switch screen {
                case .createTransaction(let transactionType, let accountFrom, let accountTo): 
                    EditTransaction(
                        transactionType: transactionType,
                        accountFrom: accountFrom,
                        accountTo: accountTo,
                        accountGroup: selectedAccountGroup.selectedAccountGroup
                    )
                }
            }
            .toolbar {
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
        .environment(path)
    }
}

#Preview {
    AccountCirclesView()
        .environment(AlertManager(handle: {_ in }))
}
