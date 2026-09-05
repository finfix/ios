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

    /// Дочерние счета редактируемого родителя — берём из vm.allAccountsGrouped (уже с
    /// восстановленной иерархией через Account.groupAccounts), а не напрямую из
    /// vm.currentAccount.childrenAccounts: тот заполнен только если экран открыт из места,
    /// которое само уже строило иерархию (например, главного экрана счетов) — здесь источник
    /// надёжен независимо от того, откуда пришёл currentAccount.
    var currentAccountChildren: [Account] {
        vm.allAccountsGrouped.first(where: { $0.id == vm.currentAccount.id })?.childrenAccounts ?? []
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
                        NavigationLink {
                            ParentAccountPickerScreen(
                                // Родитель должен быть из ТОЙ ЖЕ группы, что и сам редактируемый
                                // счёт — берём group у currentAccount, а не у selectedAccountGroup
                                // (глобально выбранной группы экрана счетов): если этот экран
                                // открыт для счёта из другой группы (например, не через обычный
                                // AccountCircleItemRoute.editAccount), selectedAccountGroup может
                                // не совпадать с реальной группой счёта.
                                accounts: vm.allAccountsGrouped.filter { $0.accountGroup.id == vm.currentAccount.accountGroup.id },
                                childType: vm.currentAccount.type,
                                parentAccountID: $vm.currentAccount.parentAccountID
                            )
                        } label: {
                            LabeledContent(
                                "Родительский счет",
                                value: accounts.first(where: { $0.id == vm.currentAccount.parentAccountID })?.name ?? "Не выбрано"
                            )
                        }
                    }
                }
            }
            if vm.mode == .update && vm.currentAccount.isParent && !currentAccountChildren.isEmpty {
                Section(header: Text("Дочерние счета")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 10)], spacing: 16) {
                        ForEach(currentAccountChildren) { child in
                            NavigationLink {
                                EditAccount(child, selectedAccountGroup: selectedAccountGroup, isHiddenView: vm.isHiddenView)
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    VStack {
                                        AccountCircleItemHeader(account: child)
                                        AccountCircleItemCircle(account: child)
                                        AccountCircleItemFooter(account: child)
                                    }
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 22))
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, .gray)
                                        .background(Circle().fill(Color(.systemBackground)))
                                        .offset(x: 8, y: -8)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            if vm.mode == .update && !vm.currentAccount.isParent && [.regular, .expense, .earnings].contains(vm.currentAccount.type) {
                Section(header: Text("Счёт-мост"), footer: Text("Счёт-мост объединяет этот счёт с другим вашим счётом (например, из другой группы) — операции по нему предлагается довнести на той стороне. Связать можно только счета одной валюты.")) {
                    if let linkedAccountID = vm.currentAccount.linkedAccountID {
                        let linkedAccount = vm.allAccountsGrouped.flatMap { [$0] + $0.childrenAccounts }.first { $0.id == linkedAccountID }
                        LabeledContent("Связан со счётом", value: linkedAccount?.name ?? linkedAccountID.uuidString.prefix(8).description)
                        Button("Отвязать", role: .destructive) {
                            vm.currentAccount.linkedAccountID = nil
                        }
                    } else {
                        NavigationLink {
                            LinkAccountGroupPickerScreen(
                                accountGroups: vm.accountGroups.filter { $0.id != vm.currentAccount.accountGroup.id },
                                allAccountsGrouped: vm.allAccountsGrouped,
                                currentAccount: vm.currentAccount,
                                linkedAccountID: $vm.currentAccount.linkedAccountID
                            )
                        } label: {
                            Text("Связать со счётом")
                        }
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


/// Первый шаг связи "счёт-мост" — выбор ГРУППЫ счетов (без текущей: мост всегда пересекает
/// границу группы, связывать со счётом собственной же группы бессмысленно). Обычный список, не
/// кружки — группы, в отличие от счетов, тут не про "коснитесь", а про явный выбор одной из.
struct LinkAccountGroupPickerScreen: View {
    let accountGroups: [AccountGroup]
    let allAccountsGrouped: [Account]
    let currentAccount: Account
    @Binding var linkedAccountID: UUID?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(accountGroups) { group in
            NavigationLink(group.name) {
                LinkAccountPickerScreen(
                    accounts: allAccountsGrouped.filter { $0.accountGroup.id == group.id },
                    currentAccount: currentAccount,
                    linkedAccountID: $linkedAccountID
                )
            }
        }
        .navigationTitle("Выбор группы счетов")
        // Экран выбора счёта (следующий шаг) закрывает СЕБЯ через dismiss() при выборе — этот
        // экран реагирует на тот же сигнал (linkedAccountID стал не nil) и закрывает СЕБЯ тоже.
        // Каждый шаг убирает только себя, поэтому не важно, на какой реальной глубине стека
        // (относительно EditAccount) сейчас находится вся цепочка — в отличие от подсчёта
        // "сколько уровней снять" вручную (path.path.removeLast(N)), который легко разъезжается
        // с реальной глубиной, если экран открыт не там, где предполагалось.
        .onChange(of: linkedAccountID) { _, newValue in
            if newValue != nil { dismiss() }
        }
    }
}

/// Второй шаг — пикер счёта внутри уже выбранной группы, переиспользует общий
/// AccountCirclePicker (та же сетка, что на главном экране счетов). Деактивирует неподходящие
/// счета: сам счёт, уже связанные, другой валюты или несовместимого типа (см.
/// EditAccountViewModel.bridgeCompatibleType) — но не убирает их из сетки.
struct LinkAccountPickerScreen: View {
    let accounts: [Account]
    let currentAccount: Account
    @Binding var linkedAccountID: UUID?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AccountCirclePicker(
            title: "Связать со счётом",
            accounts: accounts,
            isDisabled: { candidate in
                candidate.id == currentAccount.id ||
                candidate.isParent ||
                candidate.linkedAccountID != nil ||
                candidate.currency != currentAccount.currency ||
                EditAccountViewModel.bridgeCompatibleType(for: currentAccount.type) != candidate.type
            }
        ) { account in
            linkedAccountID = account.id
            dismiss()
        }
    }
}

/// Пикер родительского счёта — тоже переиспользует AccountCirclePicker, но с
/// selectsParents: true (тап по родителю сразу выбирает его, а не открывает панель детей) и
/// деактивированными не-родительскими счетами и родителями другого типа (дочерний счёт может
/// принадлежать только родителю своего же типа).
struct ParentAccountPickerScreen: View {
    let accounts: [Account]
    let childType: AccountType
    @Binding var parentAccountID: UUID?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Button("Не выбрано") {
                parentAccountID = nil
                dismiss()
            }
            .padding()
            Divider()
            AccountCirclePicker(
                title: "Родительский счёт",
                accounts: accounts,
                selectsParents: true,
                isDisabled: { !$0.isParent || $0.type != childType }
            ) { account in
                parentAccountID = account.id
                dismiss()
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
