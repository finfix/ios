//
//  AccountSelectorField.swift
//  Coin
//

import SwiftUI

/// Цвет-заглушка счёта по его типу (упрощённая версия палитры из AccountCircleItemCircle).
func accountTypeColor(_ type: AccountType) -> Color {
    switch type {
    case .balancing: return .yellow
    case .debt, .regular: return .orange
    case .expense: return .green
    case .earnings: return .blue
    }
}

/// Маленький круглый значок счёта: цвет по типу + иконка счёта.
/// Родительские счета — с двойным кольцом, как на главном экране (AccountCircleItemCircle).
struct AccountIconCircle: View {
    var account: Account
    var diameter: CGFloat = 36

    var body: some View {
        Rectangle()
            .fill(accountTypeColor(account.type))
            .mask {
                ZStack {
                    if account.isParent && account.type != .balancing {
                        Circle()
                            .fill(.clear)
                            .strokeBorder(.black, lineWidth: 2)
                            .frame(width: diameter, height: diameter)
                        Circle()
                            .frame(width: diameter * 0.9, height: diameter * 0.9)
                    } else {
                        Circle()
                            .frame(width: diameter, height: diameter)
                    }
                }
            }
            .overlay {
                AsyncImage(url: URL.documentsDirectory.appending(path: account.icon.url)) { image in
                    image.image?
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: diameter * 0.5)
                }
            }
            .frame(width: diameter, height: diameter)
    }
}

/// Строка счёта: иконка, название, валюта и баланс (или прогнозируемый баланс, если передан).
struct AccountSelectorRowContent: View {
    var account: Account
    var balanceOverride: Decimal? = nil
    var showChevron: Bool = false

    private var balance: Decimal {
        balanceOverride ?? (account.isParent ? account.showingRemainder : account.remainder)
    }

    var body: some View {
        HStack {
            AccountIconCircle(account: account)
            VStack(alignment: .leading, spacing: 1) {
                Text(account.name)
                    .lineLimit(1)
                Text(account.currency.symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(CurrencyFormatter(currency: account.currency, withUnits: false).string(number: balance))
                .foregroundStyle(balance < 0 ? .red : .primary)
                .lineLimit(1)
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Кружок счёта в стиле главного экрана (название сверху, иконка, баланс снизу).
/// По тапу вызывает `onTap` — открытие/закрытие списка выбора управляется снаружи.
/// Долгий тап (если счёт уже выбран) открывает редактирование этого счёта.
struct AccountSelectorField: View {
    var title: String
    var account: Account
    var displayedBalance: Decimal? = nil
    var isExpanded: Bool
    var accountGroup: AccountGroup
    var onTap: () -> Void

    @State private var isEditingAccount = false

    private var isSelected: Bool {
        account.id != UUID(uuid: UUID_NULL)
    }

    private var balance: Decimal {
        displayedBalance ?? (account.isParent ? account.showingRemainder : account.remainder)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(isSelected ? account.name : title)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(isSelected ? .primary : .secondary)
            AccountIconCircle(account: account, diameter: 56)
                .opacity(isSelected ? 1 : 0.4)
                .overlay {
                    if isExpanded {
                        Circle().stroke(Color.accentColor, lineWidth: 2)
                    }
                }
            Text(isSelected ? CurrencyFormatter(currency: account.currency, withUnits: false).string(number: balance) : " ")
                .font(.caption)
                .foregroundStyle(balance < 0 ? .red : .primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        // Долгий тап и обычный тап взаимоисключающие, чтобы при отпускании после долгого
        // тапа не срабатывал ещё и обычный тап (иначе он тут же закрывал/выбирал счёт).
        .gesture(
            LongPressGesture(minimumDuration: 0.6)
                .onEnded { _ in
                    if isSelected {
                        isEditingAccount = true
                    }
                }
                .exclusively(before: TapGesture().onEnded(onTap))
        )
        .sheet(isPresented: $isEditingAccount) {
            NavigationStack {
                EditAccount(account, selectedAccountGroup: accountGroup)
            }
        }
    }
}

/// Две круглые "монетки" счетов (списание/пополнение) со стрелкой перетекания денег между ними
/// и встроенным (не модальным) списком выбора, раскрывающимся под ними.
struct TransferAccountsSelector: View {
    var fromTitle: String
    @Binding var accountFrom: Account
    var accountsFrom: [Account]
    var displayedBalanceFrom: Decimal?
    @Binding var isFromPickerShowing: Bool

    var toTitle: String
    @Binding var accountTo: Account
    var accountsTo: [Account]
    var displayedBalanceTo: Decimal?
    @Binding var isToPickerShowing: Bool

    var accountGroup: AccountGroup

    @State private var drillParentFrom: Account?
    @State private var drillParentTo: Account?

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                AccountSelectorField(
                    title: fromTitle,
                    account: accountFrom,
                    displayedBalance: displayedBalanceFrom,
                    isExpanded: isFromPickerShowing,
                    accountGroup: accountGroup,
                    onTap: toggleFrom
                )
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                    .padding(.top, 20)
                AccountSelectorField(
                    title: toTitle,
                    account: accountTo,
                    displayedBalance: displayedBalanceTo,
                    isExpanded: isToPickerShowing,
                    accountGroup: accountGroup,
                    onTap: toggleTo
                )
            }
            if isFromPickerShowing {
                AccountInlinePicker(
                    accounts: accountsFrom,
                    selected: $accountFrom,
                    drillParent: $drillParentFrom,
                    onSelect: { isFromPickerShowing = false },
                    accountGroup: accountGroup
                )
            }
            if isToPickerShowing {
                AccountInlinePicker(
                    accounts: accountsTo,
                    selected: $accountTo,
                    drillParent: $drillParentTo,
                    onSelect: { isToPickerShowing = false },
                    accountGroup: accountGroup
                )
            }
        }
    }

    private func toggleFrom() {
        if isFromPickerShowing {
            isFromPickerShowing = false
            return
        }
        isFromPickerShowing = true
        isToPickerShowing = false
        drillParentFrom = accountsFrom.first { $0.childrenAccounts.contains { $0.id == accountFrom.id } }
    }

    private func toggleTo() {
        if isToPickerShowing {
            isToPickerShowing = false
            return
        }
        isToPickerShowing = true
        isFromPickerShowing = false
        drillParentTo = accountsTo.first { $0.childrenAccounts.contains { $0.id == accountTo.id } }
    }
}

/// Встроенный (не модальный) горизонтальный список выбора счёта в стиле главного экрана:
/// на верхнем уровне — все счета, тап по родительскому счёту показывает его дочерние счета
/// (и кружок возврата на уровень выше первым в ленте), тап по обычному счёту выбирает его
/// и закрывает список. Текущий выбранный счёт обведён рамкой.
struct AccountInlinePicker: View {
    var accounts: [Account]
    @Binding var selected: Account
    @Binding var drillParent: Account?
    var onSelect: () -> Void
    var accountGroup: AccountGroup

    private var currentList: [Account] {
        drillParent?.childrenAccounts ?? accounts
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                if let parent = drillParent {
                    Button {
                        drillParent = nil
                    } label: {
                        VStack(spacing: 4) {
                            Text("Назад")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Circle()
                                .fill(Color(UIColor.systemGray5))
                                .frame(width: 56, height: 56)
                                .overlay {
                                    Image(systemName: "arrow.uturn.left")
                                        .foregroundStyle(.secondary)
                                }
                            Text(parent.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(width: 70)
                    }
                    .buttonStyle(.plain)
                }
                ForEach(currentList) { account in
                    AccountInlinePickerRow(
                        account: account,
                        isHighlighted: isHighlighted(account),
                        accountGroup: accountGroup,
                        onTap: {
                            if account.isParent {
                                drillParent = account
                            } else {
                                selected = account
                                drillParent = nil
                                onSelect()
                            }
                        }
                    )
                }
                CreateAccountButton(accountType: newAccountType, accountGroup: accountGroup, parentAccountID: drillParent?.id)
            }
            .padding(.vertical, 4)
        }
    }

    /// Отмечаем сам выбранный счёт, а для родителя — если выбранный счёт лежит внутри него.
    private func isHighlighted(_ account: Account) -> Bool {
        selected.id == account.id || account.childrenAccounts.contains { $0.id == selected.id }
    }

    private var newAccountType: AccountType {
        drillParent?.type ?? accounts.first?.type ?? .regular
    }
}

/// Строка счёта в горизонтальной ленте: тап выбирает/раскрывает счёт,
/// долгий тап (если счёт уже существует) открывает его редактирование.
private struct AccountInlinePickerRow: View {
    var account: Account
    var isHighlighted: Bool
    var accountGroup: AccountGroup
    var onTap: () -> Void

    @State private var isEditingAccount = false

    var body: some View {
        VStack(spacing: 4) {
            Text(account.name)
                .font(.caption)
                .lineLimit(1)
            AccountIconCircle(account: account, diameter: 56)
                .overlay {
                    if isHighlighted {
                        Circle().stroke(Color.accentColor, lineWidth: 2)
                    }
                }
            Text(CurrencyFormatter(currency: account.currency, withUnits: false).string(
                number: account.isParent ? account.showingRemainder : account.remainder
            ))
            .font(.caption)
            .lineLimit(1)
        }
        .frame(width: 70)
        .contentShape(Rectangle())
        // Долгий тап и обычный тап взаимоисключающие — иначе при отпускании после
        // долгого тапа сразу срабатывал обычный тап и закрывал только что открытое окно.
        .gesture(
            LongPressGesture(minimumDuration: 0.6)
                .onEnded { _ in isEditingAccount = true }
                .exclusively(before: TapGesture().onEnded(onTap))
        )
        .sheet(isPresented: $isEditingAccount) {
            NavigationStack {
                EditAccount(account, selectedAccountGroup: accountGroup)
            }
        }
    }
}

/// Кружок "+" в конце ленты для создания нового счёта прямо из выбора счёта транзакции.
/// Если открыт внутри родительского счёта, новый счёт создаётся его дочерним —
/// это включает уже существующую в EditAccount фичу наследования названия от родителя.
private struct CreateAccountButton: View {
    var accountType: AccountType
    var accountGroup: AccountGroup
    var parentAccountID: UUID?

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            VStack(spacing: 4) {
                Text(" ")
                    .font(.caption)
                Circle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                Text("Счёт")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 70)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                EditAccount(
                    accountType: accountType,
                    accountGroup: accountGroup,
                    initialParentAccountID: parentAccountID
                )
            }
        }
    }
}
