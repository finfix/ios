//
//  UpdateTransaction.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "EditTransaction")

enum EditTransactionRoute: Hashable {
    case tagsList
}

struct Tags: View {
    
    var vm: EditTransactionViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(AlertManager.self) private var alert
    @Environment(PathSharedState.self) var path
    
    var body: some View {
        HStack {
            ScrollView(.horizontal) {
                VStack(alignment: .leading) {
                    HStack {
                        ForEach(Array(vm.tags.enumerated()), id: \.offset) { (i, tag) in
                            if i % 2 == 0 {
                                Button {
                                    withAnimation {
                                        if vm.currentTransaction.tags.contains(tag) {
                                            vm.currentTransaction.tags.removeAll { $0.id == tag.id }
                                        } else {
                                            vm.currentTransaction.tags.append(tag)
                                        }
                                    }
                                } label: {
                                    Text("#\(tag.name)")
                                        .font(.callout)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background {
                                            RoundedRectangle(cornerRadius: 100)
                                                .foregroundStyle(vm.currentTransaction.tags.contains(tag) ? Color.blue : Color.clear)
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 100)
                                                        .stroke(.secondary, lineWidth: 1)
                                                }
                                        }
                                }
                            }
                        }
                    }
                    HStack {
                        ForEach(Array(vm.tags.enumerated()), id: \.offset) { (i, tag) in
                            if i % 2 != 0 {
                                Button {
                                    withAnimation {
                                        if vm.currentTransaction.tags.contains(tag) {
                                            vm.currentTransaction.tags.removeAll { $0.id == tag.id }
                                        } else {
                                            vm.currentTransaction.tags.append(tag)
                                        }
                                    }
                                } label: {
                                    Text("#\(tag.name)")
                                        .font(.callout)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background {
                                            RoundedRectangle(cornerRadius: 100)
                                                .foregroundStyle(vm.currentTransaction.tags.contains(tag) ? Color.blue : Color.clear)
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 100)
                                                        .stroke(.secondary, lineWidth: 1)
                                                }
                                        }
                                }
                            }
                        }
                    }
                }
                .padding(1)
            }
            Button {
                path.path.append(EditTransactionRoute.tagsList)
            } label: {
                Image(systemName: "ellipsis")
            }
        }
        .buttonStyle(.plain)
    }
}

struct EditTransaction: View {
    
    private enum Field: Hashable {
        case amountFromSelector, amountToSelector, note
    }
    @FocusState private var focusedField: Field?
    @State private var isAmountFromFocused = false
    @State private var isAmountToFocused = false
    @State private var isAmountFromCalcMode = false
    @State private var isAmountToCalcMode = false
    
    @Environment(\.dismiss) private var dismiss
    @State private var vm: EditTransactionViewModel
    @Environment(AlertManager.self) private var alert
    
    @Environment(PathSharedState.self) var path
    
    init(_ transaction: Transaction) {
        vm = EditTransactionViewModel(
            currentTransaction: transaction,
            oldTransaction: transaction,
            accountGroup: transaction.accountFrom.accountGroup,
            mode: .update
        )
    }
    
    init(
        transactionType: TransactionType,
        accountFrom: Account = Account(),
        accountTo: Account = Account(),
        accountGroup: AccountGroup
    ) {
        vm = EditTransactionViewModel(
            currentTransaction: Transaction(
                accountingInCharts: true, 
                type: transactionType,
                accountFrom: accountFrom,
                accountTo: accountTo,
                accountGroupID: accountGroup.id
            ),
            accountGroup: accountGroup,
            mode: .create
        )
    }
    
    /// Перезагружает счета (например, после создания/редактирования счёта прямо из пикера
    /// в этом экране) и подтягивает свежие значения (баланс, название и т.п.) уже выбранных
    /// счётов списания/пополнения.
    private func refreshAccounts() {
        Task {
            do {
                try await vm.load()
                if let fresh = vm.accounts.first(where: { $0.id == vm.currentTransaction.accountFrom.id }) {
                    vm.currentTransaction.accountFrom = fresh
                }
                if let fresh = vm.accounts.first(where: { $0.id == vm.currentTransaction.accountTo.id }) {
                    vm.currentTransaction.accountTo = fresh
                }
            } catch {
                alert.error(error)
            }
        }
    }

    @ViewBuilder
    private var amountFromField: some View {
        if vm.currentTransaction.type != .balancing {
            CalculatorField(
                title: vm.suggestAmountFromString ?? (vm.intercurrency ? "Сумма списания" : "Сумма"),
                text: $vm.amountFromString,
                isFocused: Binding(
                    get: { isAmountFromFocused },
                    set: { newValue in
                        isAmountFromFocused = newValue
                        if newValue { isAmountToFocused = false }
                    }
                ),
                onDone: {
                    if vm.intercurrency {
                        isAmountToFocused = true
                    } else {
                        focusedField = .note
                    }
                },
                onCalculationModeChange: { isAmountFromCalcMode = $0 }
            )
            .frame(maxWidth: .infinity)
            .overlay(alignment: .trailing) {
                HStack {
                    Text(vm.currentTransaction.accountFrom.currency.symbol)
                    if isAmountFromCalcMode {
                        Button {
                            UIPasteboard.general.string = vm.amountFromString
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var amountToField: some View {
        if vm.intercurrency || vm.currentTransaction.type == .balancing {
            CalculatorField(
                title: vm.suggestAmountToString ?? "Сумма начисления",
                text: $vm.amountToString,
                isFocused: Binding(
                    get: { isAmountToFocused },
                    set: { newValue in
                        isAmountToFocused = newValue
                        if newValue { isAmountFromFocused = false }
                    }
                ),
                onDone: {
                    focusedField = .note
                },
                onCalculationModeChange: { isAmountToCalcMode = $0 }
            )
            .frame(maxWidth: .infinity)
            .overlay(alignment: .trailing) {
                HStack {
                    Text(vm.currentTransaction.accountTo.currency.symbol)
                    if isAmountToCalcMode {
                        Button {
                            UIPasteboard.general.string = vm.amountToString
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if vm.currentTransaction.type != .balancing {
                    TransferAccountsSelector(
                        fromTitle: "Счет списания",
                        accountFrom: $vm.currentTransaction.accountFrom,
                        accountsFrom: getAccountsForShowingInCreate(
                            accounts: vm.accounts,
                            position: .up,
                            transactionType: vm.currentTransaction.type,
                            excludedAccount: nil
                        ),
                        displayedBalanceFrom: vm.predictedAfterFrom,
                        isFromPickerShowing: $vm.shouldShowPickerAccountFrom,
                        toTitle: "Счет пополнения",
                        accountTo: $vm.currentTransaction.accountTo,
                        accountsTo: getAccountsForShowingInCreate(
                            accounts: vm.accounts,
                            position: .down,
                            transactionType: vm.currentTransaction.type,
                            excludedAccount: vm.currentTransaction.accountFrom,
                            preferredCurrency: vm.currentTransaction.accountFrom.id != UUID(uuid: UUID_NULL) ? vm.currentTransaction.accountFrom.currency : nil
                        ),
                        displayedBalanceTo: vm.predictedAfterTo,
                        isToPickerShowing: $vm.shouldShowPickerAccountTo,
                        accountGroup: vm.accountGroup,
                        onAccountChanged: refreshAccounts
                    )
                    .frame(maxWidth: .infinity)
                    .onChange(of: vm.currentTransaction.accountFrom) { _, newValue in
                        guard newValue.id != UUID(uuid: UUID_NULL) else { return }
                        // Авто-выбор счёта пополнения с той же валютой
                        if vm.currentTransaction.accountTo.id == UUID(uuid: UUID_NULL) {
                            let candidates = getAccountsForShowingInCreate(
                                accounts: vm.accounts,
                                position: .down,
                                transactionType: vm.currentTransaction.type,
                                excludedAccount: newValue
                            )
                            if let match = candidates.first(where: { !$0.isParent && $0.currency == newValue.currency }) {
                                vm.currentTransaction.accountTo = match
                            }
                        }
                    }
                }

                let showAmountTo = vm.intercurrency || vm.currentTransaction.type == .balancing
                if vm.intercurrency {
                    HStack(spacing: 16) {
                        EditCard(padding: 10) { amountFromField }
                        EditCard(padding: 10) { amountToField }
                    }
                } else {
                    VStack(spacing: 16) {
                        if vm.currentTransaction.type != .balancing {
                            EditCard(padding: 10) { amountFromField }
                        }
                        if showAmountTo {
                            EditCard(padding: 10) { amountToField }
                        }
                    }
                }
                if vm.currentTransaction.accountFrom.currency != vm.accountGroup.currency || vm.showRateString != nil {
                    VStack(alignment: .leading) {
                        if vm.currentTransaction.accountFrom.currency != vm.accountGroup.currency {
                            Text("В валюте группы счетов: " + convert(
                                    amountFrom: vm.currentTransaction.amountFrom,
                                    currencyRateFrom: vm.currentTransaction.accountFrom.currency.rate,
                                    currencyRateTo: vm.accountGroup.currency.rate
                                )
                                .currencyString(
                                    formatter: CurrencyFormatter(
                                        currency: vm.accountGroup.currency,
                                        withUnits: false
                                    )
                                )
                            )
                        }
                        if let showRateString = vm.showRateString {
                            Text("Курс: \(showRateString)")
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                }

                EditCard {
                    TextField("Заметка", text: $vm.currentTransaction.note, axis: .vertical)
                        .focused($focusedField, equals: .note)
                }

                EditCard {
                    CarouselDatePicker(selectedDate: $vm.currentTransaction.dateTransaction)
                        .onChange(of: vm.currentTransaction.dateTransaction) { _, _ in
                            Task {
                                do {
                                    try await vm.save()
                                } catch {
                                    alert.error(error)
                                    return
                                }

                                dismiss()
                            }
                        }
                }

                Button {
                    withAnimation {
                        vm.shouldShowAdditionalSettings.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName:"chevron.down")
                            .rotationEffect(.degrees(vm.shouldShowAdditionalSettings ? 180 : 0))
                        Text("\(vm.shouldShowAdditionalSettings ? "Скрыть" : "Показать") дополнительные настройки")
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain)

                if vm.shouldShowAdditionalSettings {
                    EditCard {
                        Tags(vm: vm)
                    }
                    EditCard {
                        Toggle("Учитывать транзакцию в графиках", isOn: $vm.currentTransaction.accountingInCharts)
                    }
                    if vm.mode == .create, vm.predictedAfterFrom != nil || vm.predictedAfterTo != nil {
                        EditSectionHeader("Прогноз баланса")
                        EditCard {
                            VStack(spacing: 10) {
                                if let after = vm.predictedAfterFrom {
                                    HStack {
                                        Text(vm.currentTransaction.accountFrom.name)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(CurrencyFormatter().string(number: vm.currentTransaction.accountFrom.remainder, currency: vm.currentTransaction.accountFrom.currency, withUnits: false))
                                        Image(systemName: "arrow.right")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(CurrencyFormatter().string(number: after, currency: vm.currentTransaction.accountFrom.currency, withUnits: false))
                                            .bold()
                                            .foregroundStyle(after < 0 ? .red : .primary)
                                    }
                                }
                                if let after = vm.predictedAfterTo {
                                    HStack {
                                        Text(vm.currentTransaction.accountTo.name)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        if vm.currentTransaction.type != .balancing {
                                            Text(CurrencyFormatter().string(number: vm.currentTransaction.accountTo.remainder, currency: vm.currentTransaction.accountTo.currency, withUnits: false))
                                            Image(systemName: "arrow.right")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Text(CurrencyFormatter().string(number: after, currency: vm.currentTransaction.accountTo.currency, withUnits: false))
                                            .bold()
                                    }
                                }
                            }
                        }
                    }
                    if vm.mode == .update && vm.currentTransaction.balanceAfterFrom != 0 {
                        EditSectionHeader("Баланс счетов")
                        EditCard {
                            VStack(spacing: 10) {
                                if vm.currentTransaction.type != .balancing {
                                    HStack {
                                        Text(vm.currentTransaction.accountFrom.name)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(CurrencyFormatter().string(number: vm.currentTransaction.balanceBeforeFrom, currency: vm.currentTransaction.accountFrom.currency, withUnits: false))
                                        Image(systemName: "arrow.right")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(CurrencyFormatter().string(number: vm.currentTransaction.balanceAfterFrom, currency: vm.currentTransaction.accountFrom.currency, withUnits: false))
                                            .bold()
                                    }
                                }
                                HStack {
                                    Text(vm.currentTransaction.accountTo.name)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(CurrencyFormatter().string(number: vm.currentTransaction.balanceBeforeTo, currency: vm.currentTransaction.accountTo.currency, withUnits: false))
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(CurrencyFormatter().string(number: vm.currentTransaction.balanceAfterTo, currency: vm.currentTransaction.accountTo.currency, withUnits: false))
                                        .bold()
                                }
                            }
                        }
                    }
                }
                if vm.mode == .update {
                    Button {
                        Task {
                            do {
                                try await vm.save()
                            } catch {
                                alert.error(error)
                                return
                            }

                            dismiss()
                        }
                    } label: {
                        Text("Сохранить")
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(vm.isChanged ? Color.accentColor : Color(UIColor.systemGray4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(!vm.isChanged)

                    VStack(alignment: .leading) {
                        Text("ID: \(vm.currentTransaction.id)")
                        Text("Дата и время создания: \(vm.currentTransaction.datetimeCreate, format: .dateTime)")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .toolbar {
            if vm.mode == .update {
                ToolbarItem {
                    Button(role: .destructive) {
                        Task {
                            do {
                                try await vm.deleteTransaction()
                            } catch {
                                alert.error(error)
                                return
                            }

                            dismiss()
                        }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    
                    // Если (выбранное поле = поле ввода суммы списания) И (счет списания имеет ненулевой баланс) И (тип транзакции расход ИЛИ перевод)
                    if isAmountFromFocused && vm.currentTransaction.accountFrom.remainder != 0 && (vm.currentTransaction.type == .consumption || vm.currentTransaction.type == .transfer)  {
                        
                        // Кнопка ввода всего возможного баланса в поле ввода суммы списания
                        Button("Весь баланс: " + CurrencyFormatter().string(
                                        number: vm.currentTransaction.accountFrom.remainder,
                                        currency: vm.currentTransaction.accountFrom.currency
                                    )
                        ) {
                            
                            // Присваиваем сумме списания весь баланс счета списания
                            vm.currentTransaction.amountFrom = vm.currentTransaction.accountFrom.remainder
                            vm.amountFromString = vm.currentTransaction.accountFrom.remainder.description
                            
                            // Если транзакция между счетами в разной валюте
                            if vm.intercurrency {
                                
                                // После нажатия переходим к полю ввода суммы пополнения
                                focusedField = .amountToSelector
                            } else {
                                
                                // После нажатия переходим к полю ввода заметки
                                focusedField = .note
                            }
                        }
                    }
                    Spacer()
                    
                    // Кнопка Следующее поле / Сохранить над клавиатурой
                    Button(focusedField == .note ? "Готово" : "Следующее поле") {
                        
                        // Конфигурируем логику нажатия на кнопку на клавиатуре в зависимости от поля, на котором сейчас стоим
                        switch focusedField {
                        case  .amountFromSelector: // Поле ввода суммы списания
                            
                            // Если транзакция между счетами с разными валютами
                            if vm.intercurrency {
                                
                                // Переходим к полю ввода суммы пополнения
                                focusedField = .amountToSelector
                            } else {
                                
                                // Переходим к полю заметки
                                focusedField = .note
                            }
                        case .amountToSelector: // Поле выбора суммы пополнения
                            
                            // Переходим к полю ввода заметки
                            focusedField = .note
                            
                        case .note: // Поле ввода заметки
                            focusedField = nil
                        default:
                            focusedField = nil
                        }
                    }
                }
            }
        }
        .task {
            if vm.mode == .create {
                if vm.currentTransaction.accountFrom.id == UUID(uuid: UUID_NULL) {
                    vm.shouldShowPickerAccountFrom = true
                } else {
                    isAmountFromFocused = true
                }
            }
            do {
                try await vm.load()
            } catch {
                alert.error(error)
            }
        }
    }
}

#Preview {
    EditTransaction(
        transactionType: .consumption,
        accountGroup: AccountGroup(id: UUID())
    )
    .environment(AlertManager(handle: {_ in }))
}

/// Карточка-контейнер, заменяющая гриду Form's Section там, где нужен серый фон
/// (Form/Section больше не используется на этом экране).
private struct EditCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// Заголовок группы (аналог заголовка Section("...") у Form).
private struct EditSectionHeader: View {
    var title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }
}

enum Position {
    case up, down
}

func getAccountsForShowingInCreate(accounts: [Account], position: Position, transactionType: TransactionType, excludedAccount: Account?, preferredCurrency: Currency? = nil) -> [Account] {
    var subfiltered = accounts.filter { $0.visible && $0.id != excludedAccount?.id ?? UUID(uuid: UUID_NULL) }

    switch transactionType {
    case .consumption:
        switch position {
        case .up:
            subfiltered = subfiltered.filter { $0.type == .regular || $0.type == .debt }
        case .down:
            subfiltered = subfiltered.filter { $0.type == .expense }
        }
    case .transfer:
        subfiltered = subfiltered.filter { $0.type == .regular || $0.type == .debt }
    case .income:
        switch position {
        case .up:
            subfiltered = subfiltered.filter { $0.type == .earnings }
        case .down:
            subfiltered = subfiltered.filter { $0.type == .regular || $0.type == .debt }
        }
    default:
        subfiltered = []
    }
    var grouped = Account.groupAccounts(subfiltered.sorted(by: { $1.rank > $0.rank }))
    if let currency = preferredCurrency {
        // Сортируем дочерние счета внутри каждого родителя: совпадающая валюта — первой
        for i in grouped.indices {
            grouped[i].childrenAccounts = grouped[i].childrenAccounts.sorted { a, _ in
                a.currency == currency
            }
        }
        // Сортируем родительские/одиночные счета: совпадающая валюта или дети с совпадающей валютой — первыми
        grouped = grouped.sorted { a, _ in
            if a.currency == currency { return true }
            if a.childrenAccounts.contains(where: { $0.currency == currency }) { return true }
            return false
        }
    }
    return grouped
}
