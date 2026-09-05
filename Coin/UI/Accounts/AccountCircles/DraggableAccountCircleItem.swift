//
//  DraggableAccountCircleItem.swift
//  Coin
//
//  Created by Илья on 28.05.2024.
//

import SwiftUI

struct DraggableAccountCircleItem: View {

    @Binding var vm: AccountCirclesViewModel
    let account: Account
    @Binding var path: NavigationPath
    // true для кружков внутри плавающей панели дочерних счетов (см. vm.expandedParentAccount) —
    // тап/долгий тап там должен ещё и закрыть панель, а не просто выполнить своё обычное действие.
    var isAlreadyOpened: Bool = false

    private func closeIfNested() {
        if isAlreadyOpened {
            vm.closeExpandedPanel()
        }
    }

    // Задержать перетаскиваемый счёт над другим родительским на 1 секунду при создании
    // транзакции (не в режиме редактирования) — открывает панель ЭТОГО родителя, чтобы уронить
    // именно на нужный дочерний счёт (например, по валюте), а не полагаться на авто-выбор
    // первого ребёнка.
    @State private var hoverExpandTask: Task<Void, Never>?

    private func handleHoverExpand(targeted: Bool) {
        hoverExpandTask?.cancel()
        hoverExpandTask = nil
        guard targeted, !vm.isEditMode, account.isParent, !account.childrenAccounts.isEmpty else { return }
        hoverExpandTask = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            withAnimation {
                // Открываем на той же высоте, где сейчас палец (ручной драг живьём знает
                // координаты — в отличие от нативного .draggable, тут это не требует
                // GeometryReader на том же узле, что и жест, и не рискует крэшем
                // _UIPlatterView).
                vm.expandedParentAccountAnchorY = vm.draggableLocation?.y
                vm.expandedParentAccount = account
            }
        }
    }

    // Текущий угол поворота — анимируется императивно через withAnimation(repeatForever),
    // а не через `.animation(_:value:)`: тот запускает переход только один раз при смене
    // vm.isEditMode и не гарантирует непрерывное покачивание туда-сюда (а заодно утаскивает
    // в тот же repeatForever-цикл и transition карандашика, отсюда мигание).
    @State private var jiggleRotation: Double = 0

    // Небольшая вариация угла/задержки по id счёта — чтобы кружки в режиме редактирования
    // тряслись вразнобой, а не идеально синхронно, как на главном экране iOS.
    private var jiggleAngle: Double {
        abs(account.id.hashValue) % 2 == 0 ? 1.6 : -1.6
    }
    private var jiggleDelay: Double {
        Double(abs(account.id.hashValue) % 5) * 0.02
    }

    private func startJiggleIfNeeded() {
        guard vm.isEditMode else {
            jiggleRotation = 0
            return
        }
        withAnimation(.easeInOut(duration: 0.14).repeatForever(autoreverses: true).delay(jiggleDelay)) {
            jiggleRotation = jiggleAngle
        }
    }

    // В режиме редактирования тащить (чтобы переставить) можно любой счёт — остаётся на
    // нативном .draggable/.dropDestination (небольшая задержка перед "поднятием" здесь уместна,
    // как при перестановке иконок на Home Screen).
    private var canDrag: Bool {
        vm.isEditMode
    }

    // Вне режима редактирования тащить (чтобы создать транзакцию) можно только обычные и
    // доходные счета — balancing/expense не могут быть источником. Это отдельный, обычный
    // DragGesture (не .draggable) — см. AccountCirclesViewModel MARK: Создание транзакции —
    // у .draggable на тач-экране всегда есть системная задержка "прижать-и-подождать" перед
    // стартом драга (не настраивается публичным API), а транзакцию нужно тащить сразу по
    // движению пальца, без залипания.
    private var canManualDrag: Bool {
        !vm.isEditMode && account.type != .balancing && account.type != .expense
    }

    var body: some View {

        VStack {
            AccountCircleItemHeader(account: account)
            ZStack {
                AccountCircleItemCircle(account: account)
                    .opacity(vm.isHighligted(for: account) ? 0.6 : 1)
                    .contentShape(Circle())
                    .modifier(DraggableIf(isEnabled: canDrag, account: account))
                    .dropDestination(for: DraggedAccount.self) { items, _ in
                        guard let dragged = items.first else { return false }
                        Task { await vm.handleDrop(dragged, onto: account) }
                        return true
                    } isTargeted: { targeted in
                        vm.setHighlighted(account, targeted: targeted)
                    }
                    // Любой счёт (в т.ч. balancing/expense — они могут быть только целью, не
                    // источником) регистрирует свою позицию для ручного хит-теста создания
                    // транзакции. .background(GeometryReader) — отдельный слой, а не модификатор
                    // на этом же узле, что и .draggable: иначе (проверено на практике) ловим крэш
                    // "_UIPlatterView as a subview of UIHostingController.view is not supported".
                    //
                    // Гибрид: пассивный onGeometryChange живьём ловит любое реальное изменение
                    // фрейма (в т.ч. то, что не предусмотрено явным триггером — например, смену
                    // ориентации или resize окна), а .onChange(of: vm.geometryRefreshTrigger)
                    // остаётся как явный, управляемый путь на конкретные события (смена страницы,
                    // смена набора счетов — см. AccountsTabView/applyObservedAccounts). Раньше
                    // онGeometryChange одного его было мало (TabView(.page) не всегда сообщал
                    // SwiftUI о реальном релэйауте), но корень той проблемы — сам TabView(.page) —
                    // уже заменён на ScrollView, так что пассивный путь снова безопасен.
                    .background {
                        GeometryReader { proxy in
                            Color.clear
                                .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { newValue in
                                    vm.registerCreateTransactionLocation(
                                        CGPoint(x: newValue.midX, y: newValue.midY),
                                        for: account.id
                                    )
                                }
                                .onChange(of: vm.geometryRefreshTrigger) { _, _ in
                                    let frame = proxy.frame(in: .global)
                                    vm.registerCreateTransactionLocation(
                                        CGPoint(x: frame.midX, y: frame.midY),
                                        for: account.id
                                    )
                                }
                        }
                    }
                    .modifier(ManualDragIf(isEnabled: canManualDrag, account: account, vm: $vm, path: $path))
                    .onChange(of: vm.isHighligted(for: account)) { _, targeted in
                        handleHoverExpand(targeted: targeted)
                    }
                    // Вход в режим редактирования — долгим тапом по ФОНУ экрана (см.
                    // AccountCirclesView), не по самому кружку: LongPressGesture прямо на
                    // кружке уже пробовали и откатывали — конкурирует за распознавание касания
                    // с собственными touch-жестами кружка (.draggable/ручной DragGesture).
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded {
                                // Работает и в режиме редактирования — панель детей полезна и
                                // там (быстрый доступ к их карандашам, см. isAlreadyOpened ниже),
                                // а с .draggable (тоже на этом кружке в edit mode) двойной тап не
                                // конфликтует — тот распознаёт press-and-hold, а не быстрый
                                // повторный тап.
                                if !account.childrenAccounts.isEmpty {
                                    withAnimation {
                                        vm.expandedParentAccount = account
                                        // Двойной тап — не драг, координировать не с чем, панель
                                        // просто по центру экрана.
                                        vm.expandedParentAccountAnchorY = nil
                                    }
                                }
                            }
                    )
                    .gesture(
                        TapGesture(count: 1)
                            .onEnded {
                                if vm.isEditMode {
                                    path.append(AccountCircleItemRoute.editAccount(account))
                                    return
                                }

                                closeIfNested()

                                var chartType: ChartType = .earningsAndExpenses
                                switch account.type {
                                case .earnings:
                                    chartType = .earnings
                                case .expense:
                                    chartType = .expenses
                                default: break
                                }

                                path.append(AccountCircleItemRoute.accountTransactions(account, chartType))
                            }
                    )

                // Карандаш — в режиме редактирования (любой кружок) и в панели дочерних счетов
                // родителя (двойной тап), даже вне режима редактирования: панель — это уже
                // "провалились посмотреть детей", быстрый доступ к их редактированию там уместен
                // сам по себе, без необходимости отдельно включать редактирование всей сетки.
                if vm.isEditMode || isAlreadyOpened {
                    Button {
                        closeIfNested()
                        path.append(AccountCircleItemRoute.editAccount(account))
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .gray)
                            .background(Circle().fill(Color(.systemBackground)))
                    }
                    .offset(x: 26, y: -26)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .rotationEffect(.degrees(jiggleRotation))
            AccountCircleItemFooter(account: account)
        }
        .frame(width: 80)
        .opacity(account.accountingInHeader ? 1 : 0.5)
        .onAppear {
            startJiggleIfNeeded()
        }
        .onChange(of: vm.isEditMode) { _, _ in
            startJiggleIfNeeded()
        }
        .onDisappear {
            hoverExpandTask?.cancel()
            vm.clearCreateTransactionLocation(for: account.id)
        }
    }
}



#Preview {
    DraggableAccountCircleItem(
        vm: .constant(AccountCirclesViewModel()),
        account: Account(),
        path: .constant(NavigationPath()),
        isAlreadyOpened: false
    )
}
