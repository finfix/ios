//
//  AccountCirclePicker.swift
//  Coin
//

import SwiftUI

/// Переиспользуемый "выберите счёт касанием" — та же визуальная структура, что и на главном
/// экране счетов (AccountCirclesView): три отдельные строки по типу счёта (доход/обычные/расход)
/// с разделителями между ними, те же кружки (AccountCircleItemHeader/Circle/Footer). В отличие
/// от главного экрана — без драга, без режима редактирования и без пейджинга (тут счетов обычно
/// заметно меньше, простой вертикальный скролл). Тап по обычному счёту сразу вызывает onSelect,
/// тап по родительскому — оверлей-панель с дочерними счетами (как двойной тап на главном экране,
/// см. AccountCirclesView.ExpandedChildrenPanel), а не переход. Сценарная логика (что делать при
/// выборе) остаётся снаружи, в onSelect — компонент про неё ничего не знает.
struct AccountCirclePicker: View {
    let title: String
    let accounts: [Account]

    /// true — тап по ЛЮБОМУ счёту (в т.ч. родительскому) сразу вызывает onSelect, без открытия
    /// панели дочерних. Нужен сценариям, где выбирают именно родительский/агрегирующий счёт
    /// (см. EditAccount "Родительский счёт") — по умолчанию false (обычное поведение "коснитесь
    /// счёта": родитель открывает панель, выбрать можно только обычный/дочерний счёт).
    var selectsParents: Bool = false

    /// Счета, не подходящие для текущей задачи (например, другая валюта, уже связан, это же
    /// вложение) — визуально приглушены и не реагируют на тап, но остаются на своём месте в
    /// сетке (не пропадают), чтобы сохранить наглядность структуры. К родителю в режиме
    /// drill-down (selectsParents == false) сам критерий не применяется напрямую (родитель не
    /// выбирается тапом, тап открывает панель) — вместо этого родитель деактивируется, только
    /// если ВСЕ его дети не проходят критерий (иначе валидный ребёнок с "неподходящим" по
    /// собственным полям родителем стал бы недостижим, но заходить в панель без единого
    /// подходящего варианта тоже незачем).
    var isDisabled: (Account) -> Bool = { _ in false }

    /// Счёт, который стоит явно выделить как ориентир (например, счёт-мост при довнесении
    /// переноса — сам он не выбирается, но полезно видеть, куда именно "приедет" транзакция,
    /// особенно когда контекст переноса — это транзакция ДРУГОЙ группы счетов, а тут показана
    /// СВОЯ). Обводка + подпись под именем, без влияния на disabled/тап.
    var highlightedAccountID: UUID? = nil

    /// Подпись под подсвеченным счётом — направление денег зависит от роли счёта в итоговой
    /// транзакции (accountFrom/accountTo), поэтому "сюда" по умолчанию годится не всегда:
    /// передавайте "отсюда", если подсвеченный счёт будет ИСТОЧНИКОМ денег, а не получателем.
    var highlightedAccountLabel: String = "сюда"

    let onSelect: (Account) -> Void

    @State private var expandedParent: Account?

    private var topLevelAccounts: [Account] {
        accounts.filter { $0.parentAccountID == nil }
    }

    // Та же группировка, что и в AccountCirclesView.body.
    private var earningsAccounts: [Account] {
        topLevelAccounts.filter { $0.type == .earnings || ($0.type == .balancing && $0.showingRemainder < 0) }
    }
    private var regularAccounts: [Account] {
        topLevelAccounts.filter { $0.type == .regular }
    }
    private var expenseAccounts: [Account] {
        topLevelAccounts.filter { $0.type == .expense || ($0.type == .balancing && $0.showingRemainder > 0) }
    }

    private let columns = [GridItem(.adaptive(minimum: 80), spacing: 10)]

    private func circle(_ account: Account) -> some View {
        let isDrillDown = !selectsParents && !account.childrenAccounts.isEmpty
        // Родитель как узел drill-down сам не выбирается (isDisabled к нему не применяется —
        // см. комментарий у isDisabled), НО если внутри вообще нет ни одного подходящего
        // ребёнка, заходить в панель незачем — деактивируем и сам родитель, проверяя критерий
        // на его детях, а не на нём самом.
        let disabled = isDrillDown
            ? account.childrenAccounts.allSatisfy(isDisabled)
            : isDisabled(account)
        let isHighlighted = account.id == highlightedAccountID
        return Button {
            if isDrillDown {
                withAnimation { expandedParent = account }
            } else {
                onSelect(account)
            }
        } label: {
            VStack {
                AccountCircleItemHeader(account: account)
                AccountCircleItemCircle(account: account)
                    .overlay {
                        if isHighlighted {
                            Circle().stroke(Color.accentColor, lineWidth: 3)
                        }
                    }
                if isHighlighted {
                    Text(highlightedAccountLabel)
                        .font(.caption2.bold())
                        .foregroundStyle(Color.accentColor)
                }
                AccountCircleItemFooter(account: account)
            }
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.35 : 1)
    }

    private func row(_ accounts: [Account]) -> some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(accounts) { account in
                circle(account)
            }
        }
        .padding(.horizontal)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !earningsAccounts.isEmpty {
                    row(earningsAccounts)
                }
                if !earningsAccounts.isEmpty && !regularAccounts.isEmpty {
                    Divider()
                }
                if !regularAccounts.isEmpty {
                    row(regularAccounts)
                }
                if !regularAccounts.isEmpty && !expenseAccounts.isEmpty {
                    Divider()
                }
                if !expenseAccounts.isEmpty {
                    row(expenseAccounts)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(title)
        .overlay {
            if let expandedParent {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation { self.expandedParent = nil }
                        }
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(expandedParent.childrenAccounts) { child in
                                circle(child)
                                    .frame(width: 80)
                            }
                        }
                        .padding()
                    }
                    .frame(height: 140)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                }
                .transition(.opacity)
            }
        }
    }
}
