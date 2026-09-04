//
//  CreateAccount.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI
import Factory

struct EditAccount: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(AlertManager.self) private var alert

    @State private var vm: EditAccountViewModel

    @FocusState private var isNameFocused: Bool
    @State private var isRemainderFocused = false
    @State private var isRemainderCalcMode = false
    @State private var isBudgetAmountFocused = false
    @State private var isBudgetFixedSumFocused = false
    @State private var isBudgetDaysOffsetFocused = false

    var selectedAccountGroup: AccountGroup

    /// Родитель, которому нужно назначить создаваемый счёт (например, при создании
    /// прямо из выбора счёта в транзакции внутри уже раскрытого родительского счёта).
    /// Присваивается уже после загрузки счетов, чтобы сработала фича наследования названия.
    var initialParentAccountID: UUID?

    var accounts: [Account] {
        vm.accounts.filter {
            $0.accountGroup == selectedAccountGroup
        }
    }

    init(_ account: Account, selectedAccountGroup: AccountGroup, isHiddenView: Bool = false) {
        vm = EditAccountViewModel(
            currentAccount: account,
            oldAccount: account,
            mode: .update,
            isHiddenView: isHiddenView
        )
        self.selectedAccountGroup = selectedAccountGroup
    }

    init(accountType: AccountType, accountGroup: AccountGroup, initialParentAccountID: UUID? = nil) {
        vm = EditAccountViewModel(
            currentAccount: Account(
                type: accountType,
                accountGroup: accountGroup,
                currency: accountGroup.currency
            ),
            mode: .create
        )
        self.selectedAccountGroup = accountGroup
        self.initialParentAccountID = initialParentAccountID
    }
        
    var body: some View {
        Form {
            if vm.mode == .create {
                Section {
                    Picker("", selection: $vm.currentAccount.isParent) {
                        Text("Обычный счет")
                            .tag(false)
                        Text("Родительский счет")
                            .tag(true)
                    }
                    .pickerStyle(.segmented)
                }
            }
            Section {
                
                TextField("Название счета", text: $vm.currentAccount.name)
                    .focused($isNameFocused)

                if vm.permissions.changeRemainder {
                    CalculatorField(
                        title: vm.mode == .create ? "Начальный баланс" : "Баланс",
                        value: $vm.remainder,
                        isFocused: $isRemainderFocused,
                        onCalculationModeChange: { isRemainderCalcMode = $0 }
                    )
                        .overlay(alignment: .trailing) {
                            HStack {
                                Text(vm.currentAccount.currency.symbol)
                                if isRemainderCalcMode {
                                    Button {
                                        UIPasteboard.general.string = NumberFormatters.textField.string(from: NSNumber(value: vm.remainder))
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }

                    // Если валюта счета отличается от валюты группы счетов — показываем баланс
                    // ещё и в валюте группы, для ориентира (сам счёт при этом хранится и
                    // сохраняется по-прежнему в своей собственной валюте).
                    if vm.currentAccount.currency != selectedAccountGroup.currency {
                        HStack {
                            Text("В валюте группы")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(CurrencyFormatter().string(
                                number: vm.currentAccount.remainder * (selectedAccountGroup.currency.rate / vm.currentAccount.currency.rate),
                                currency: selectedAccountGroup.currency
                            ))
                                .foregroundStyle(.secondary)
                        }
                        .font(.footnote)
                    }
                }

            }
            
            if vm.permissions.changeBudget {
                Section(header: Text("Бюджет")) {
                    CalculatorField(
                        title: "Бюджет",
                        value: $vm.budgetAmount,
                        isFocused: $isBudgetAmountFocused
                    )
                        .overlay(alignment: .trailing) {
                            Text(vm.currentAccount.currency.symbol)
                        }
                    if vm.currentAccount.budgetAmount != 0 {
                        CalculatorField(
                            title: "Фиксированная сумма",
                            value: $vm.budgetFixedSum,
                            isFocused: $isBudgetFixedSumFocused
                        )
                            .overlay(alignment: .trailing) {
                                Text(vm.currentAccount.currency.symbol)
                            }
                        if vm.currentAccount.budgetFixedSum != 0 {
                            CalculatorField(
                                title: "Отступ в днях",
                                value: Binding(
                                    get: { Double(vm.currentAccount.budgetDaysOffset) },
                                    set: { vm.currentAccount.budgetDaysOffset = Int8(clamping: Int($0.rounded())) }
                                ),
                                isFocused: $isBudgetDaysOffsetFocused,
                                allowsOperators: false
                            )
                                .overlay(alignment: .trailing) {
                                    Text("дней")
                                }
                        }
                    }
                    Toggle("Плавное заполнение бюджета", isOn: $vm.currentAccount.budgetGradualFilling)
                }
            }
            
            Section {
                
                Toggle("Учитывать ли счет в шапке", isOn: $vm.currentAccount.accountingInHeader)
                    .disabled(!vm.currentAccount.visible)
                Toggle("Учитывать ли счет на графиках", isOn: $vm.currentAccount.accountingInCharts)
                if vm.mode == .update {
                    Toggle("Видимость счета", isOn: $vm.currentAccount.visible)
                }
                
                if vm.mode == .create || vm.permissions.changeCurrency {
                    NavigationLink {
                        CurrencyPicker(selectedCurrency: $vm.currentAccount.currency, currencies: vm.currencies)
                    } label: {
                        LabeledContent("Валюта", value: vm.currentAccount.currency.code)
                    }
                }
                NavigationLink("Иконка", destination: IconPicker(selectedIcon: $vm.currentAccount.icon))
            }
            Section {
                if vm.mode == .update {
                    let accountsToReorder: [Account] = vm.currentAccount.parentAccountID == nil
                        ? Account.groupAccounts(accounts)
                        : accounts.filter { $0.parentAccountID == vm.currentAccount.parentAccountID! }
                            .sorted { $0.rank < $1.rank }
                    NavigationLink("Изменить порядок счетов") {
                        ReorderAccountsView(accounts: accountsToReorder)
                    }
                }
                if vm.permissions.changeParentAccountID {
                    Section {
                        Picker("Родительский счет", selection: $vm.currentAccount.parentAccountID) {
                            Text("Не выбрано")
                                .tag(nil as UUID?)
                            ForEach(accounts.filter{ $0.isParent }) { account in
                                Text(account.name)
                                    .tag(account.id as UUID?)
                            }
                        }
                    }
                }
            }
            if vm.mode == .update && [.regular, .expense, .earnings].contains(vm.currentAccount.type) {
                Section(header: Text("Счёт-мост"), footer: Text("Счёт-мост объединяет этот счёт с другим вашим счётом (например, из другой группы) — операции по нему предлагается довнести на той стороне. Связать можно только счета одной валюты.")) {
                    if let linkedAccountID = vm.currentAccount.linkedAccountID {
                        let linkedAccount = vm.linkableAccounts.first { $0.id == linkedAccountID }
                        LabeledContent("Связан со счётом", value: linkedAccount?.name ?? linkedAccountID.uuidString.prefix(8).description)
                        Button("Отвязать", role: .destructive) {
                            vm.currentAccount.linkedAccountID = nil
                        }
                    } else {
                        NavigationLink {
                            LinkAccountPicker(accounts: vm.linkableAccounts) { account in
                                vm.currentAccount.linkedAccountID = account.id
                            }
                        } label: {
                            if vm.linkableAccounts.isEmpty {
                                Text("Нет подходящих счетов для связи")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Связать со счётом")
                            }
                        }
                        .disabled(vm.linkableAccounts.isEmpty)
                    }
                }
            }
            Section {
                Button {
                    Task {
                        do {
                            switch vm.mode {
                            case .create:
                                try await vm.createAccount()
                            case .update:
                                try await vm.updateAccount()
                            }
                        } catch {
                            alert.error(error)
                            return
                        }
                        
                        dismiss()
                    }
                } label: {
                    Text("Сохранить")
                }
                .frame(maxWidth: .infinity)
                .disabled(!vm.isChanged)
            }
            if vm.mode == .update {
                Section {
                    NavigationLink {
                        AuditLogHistoryView(
                            entity: .account,
                            entityID: vm.currentAccount.id.uuidString,
                            accountGroupID: selectedAccountGroup.id
                        )
                    } label: {
                        Text("Посмотреть историю изменений")
                    }
                }
            }
            if vm.currentAccount.id != UUID(uuid: UUID_NULL) {
                Section {
                    NavigationLink {
                        TransactionsView(
                            filters: TransactionFilters(
                                accounts: [vm.currentAccount],
                                accountGroups: [selectedAccountGroup]
                            ),
                            chartType: vm.currentAccount.type == .earnings ? .earnings : 
                                      vm.currentAccount.type == .expense ? .expenses : .earningsAndExpenses
                        )
                    } label: {
                        Label("Просмотреть все транзакции", systemImage: "list.bullet")
                    }
                }
                
                Section(footer:
                    VStack(alignment: .leading) {
                        CopyableIDText(id: vm.currentAccount.id.uuidString)
                        Text("Дата и время создания: \(vm.currentAccount.datetimeCreate, format: .dateTime)")
                    }
                ) {}
            }
        }
        .onChange(of: vm.currentAccount.parentAccountID) { _, newValue in
            guard vm.currentAccount.name.isEmpty, let parentID = newValue else { return }
            if let parentAccount = accounts.first(where: { $0.id == parentID }) {
                vm.currentAccount.name = parentAccount.name
            }
        }
        .onChange(of: vm.currentAccount.visible) { _, newValue in
            if !newValue {
                vm.currentAccount.accountingInHeader = false
            }
        }
        .navigationTitle(vm.mode == .create ? "Cоздание счета" : "Изменение счета")
        .onAppear {
            if vm.mode == .create {
                isNameFocused = true
            }
        }
        .task {
            do {
                try await vm.load(accountGroup: selectedAccountGroup)
                if let initialParentAccountID {
                    vm.currentAccount.parentAccountID = initialParentAccountID
                }
            } catch {
                alert.error(error)
            }
        }
        .toolbar(content: {
            ToolbarItem {
                Button(role: .destructive) {
                    Task {
                        do {
                            try await vm.deleteAccount()
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
        })
    }
}

#Preview("Создание счета") {
        EditAccount(
            accountType: .expense,
            accountGroup:
                AccountGroup(
                    currency:
                        Currency(
                            symbol: "$"
                        )
                )
        )
        .environment(AlertManager(handle: {_ in }))
}

#Preview("Редактирование счета") {
    EditAccount(
        Account(
            accountingInHeader: true,
            accountingInCharts: true,
            icon: Icon(id: UUID()),
            name: "Тестовый счет",
            type: .expense,
            visible: true,
            rank: "2",
            isParent: false,
            budgetAmount: 1000,
            showingBudgetAmount: 1000,
            budgetFixedSum: 500,
            budgetDaysOffset: 5,
            budgetGradualFilling: true,
            datetimeCreate: Date.now,
            accountGroup: AccountGroup(id: UUID()),
            currency: Currency(symbol: "$")
        ),
        selectedAccountGroup: AccountGroup(),
        isHiddenView: false
    )
    .environment(AlertManager(handle: {_ in }))
}


/// Пикер счёта для связи "счёт-мост" — только среди своих же счетов (см.
/// EditAccountViewModel.linkableAccounts): совместимый тип, та же валюта, ещё не связан.
/// Трёхшаговый drill-down: группа счетов → родительский счёт (если есть) → дочерний счёт —
/// выбрать можно только реальный (дочерний либо не имеющий родителя) счёт, не агрегат.
struct LinkAccountPicker: View {
    let accounts: [Account]
    let onSelect: (Account) -> Void

    private var accountGroups: [AccountGroup] {
        var seen = Set<UUID>()
        return accounts.compactMap { account in
            guard seen.insert(account.accountGroup.id).inserted else { return nil }
            return account.accountGroup
        }
    }

    var body: some View {
        List(accountGroups) { group in
            NavigationLink(group.name) {
                LinkAccountGroupPicker(
                    accounts: accounts.filter { $0.accountGroup.id == group.id },
                    onSelect: onSelect
                )
            }
        }
        .navigationTitle("Выбор группы счетов")
    }
}

/// Второй шаг — родительские счета этой группы (ведут к дочерним) и счета без родителя
/// (выбираются сразу).
private struct LinkAccountGroupPicker: View {
    let accounts: [Account]
    let onSelect: (Account) -> Void

    private var parents: [Account] { accounts.filter { $0.isParent } }
    private var standalone: [Account] { accounts.filter { !$0.isParent && $0.parentAccountID == nil } }

    var body: some View {
        List {
            if !parents.isEmpty {
                Section {
                    ForEach(parents) { parent in
                        NavigationLink(parent.name) {
                            LinkAccountChildPicker(
                                parentName: parent.name,
                                children: accounts.filter { $0.parentAccountID == parent.id },
                                onSelect: onSelect
                            )
                        }
                    }
                }
            }
            if !standalone.isEmpty {
                Section {
                    ForEach(standalone) { account in
                        SelectableAccountRow(account: account, onSelect: onSelect)
                    }
                }
            }
        }
        .navigationTitle("Выбор счёта")
    }
}

/// Третий шаг — дочерние счета выбранного родителя, финальный выбор.
private struct LinkAccountChildPicker: View {
    let parentName: String
    let children: [Account]
    let onSelect: (Account) -> Void

    var body: some View {
        List(children) { account in
            SelectableAccountRow(account: account, onSelect: onSelect)
        }
        .navigationTitle(parentName)
    }
}

private struct SelectableAccountRow: View {
    @Environment(\.dismiss) var dismiss
    let account: Account
    let onSelect: (Account) -> Void

    var body: some View {
        Button {
            onSelect(account)
            dismiss()
        } label: {
            HStack {
                Text(account.name)
                Spacer()
                Text(account.currency.code)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct IconPicker: View {
    
    @Injected(\.service) private var service
    
    @State var icons: [Icon] = []
    @Environment(\.dismiss) var dismiss

    @Binding var selectedIcon: Icon
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
                ForEach(icons) { icon in
                    Button {
                        selectedIcon = icon
                        dismiss()
                    } label: {
                        Circle()
                            .fill(.orange)
                            .frame(height: 60)
                            .overlay{
                                AsyncImage(url: URL.documentsDirectory.appending(path: icon.url)) { image in
                                    image.image?
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 30)
                                }
                            }
                    }
                }
            }
        }
        .task {
            do {
                self.icons = try await service.getIcons()
            } catch {
                
            }
        }
    }
}
