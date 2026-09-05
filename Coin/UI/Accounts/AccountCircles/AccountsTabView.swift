//
//  AccountCircleView.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI
import OSLog
import Factory

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
