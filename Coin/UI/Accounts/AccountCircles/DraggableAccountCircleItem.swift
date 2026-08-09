//
//  DraggableAccountCircleItem.swift
//  Coin
//
//  Created by Илья on 28.05.2024.
//

import SwiftUI

struct AccountLocationPreferenceKey: PreferenceKey {
    static var defaultValue: [Account: CGPoint] = [:]
    
    static func reduce(value: inout [Account: CGPoint], nextValue: () -> [Account: CGPoint]) {
        value.merge(nextValue()) { current, _ in current }
    }
}

struct DragLocationPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint?
    
    static func reduce(value: inout CGPoint?, nextValue: () -> CGPoint?) {
        value = nextValue()
    }
}

struct DraggableAccountCircleItem: View {
    
    @Binding var vm: AccountCirclesViewModel
    let accountGroup: AccountGroup
    let account: Account
    @Binding var path: NavigationPath
    @State var isChildrenOpen = false
    @Environment(\.dismiss) var dismiss
    var isAlreadyOpened: Bool = false

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

    var body: some View {

        VStack {
            AccountCircleItemHeader(account: account)
            ZStack {
                AccountCircleItemCircle(account: account)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(
                                    key: AccountLocationPreferenceKey.self,
                                    value: [account: CGPoint(
                                        x: proxy.frame(in: .global).midX,
                                        y: proxy.frame(in: .global).midY
                                    )]
                                )
                        }
                    )
                    .onPreferenceChange(AccountLocationPreferenceKey.self) { locations in
                        if let location = locations[account] {
                            vm.initializateStaticLocations(
                                location: location,
                                for: account,
                                in: accountGroup
                            )
                        }
                    }
                    .allowsHitTesting(false)
                
                Circle()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white.opacity(0.001))
                    .gesture(
                        DragGesture(coordinateSpace: .global)
                            .onChanged { state in
                                guard !vm.isEditMode, account.type != .balancing && account.type != .expense else { return }
                                vm.updateDraggableLocation(
                                    location: state.location,
                                    for: account
                                )
                            }
                            .onEnded { state in
                                guard !vm.isEditMode else { return }
                                confirmDraggableDrop(for: account)
                                if isAlreadyOpened {
                                    dismiss()
                                }
                            }
                    )
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { state in
                                withAnimation {
                                    vm.isEditMode = true
                                }
                            }
                    )
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded {
                                guard !vm.isEditMode else { return }
                                if !account.childrenAccounts.isEmpty {
                                    isChildrenOpen = true
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

                                if isAlreadyOpened {
                                    dismiss()
                                }

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

                if vm.isEditMode {
                    Button {
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
            .opacity(vm.isHighligted(for: account) ? 0.6 : 1)
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
        .popover(isPresented: $isChildrenOpen) {
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(account.childrenAccounts) { account in
                        DraggableAccountCircleItem(
                            vm: $vm,
                            accountGroup: accountGroup,
                            account: account,
                            path: $path,
                            isAlreadyOpened: true
                        )
                        .frame(width: 80)
                    }
                    .presentationCompactAdaptation(.popover)
                }
                .padding()
            }
        }
    }
    
    func confirmDraggableDrop(for draggableAccount: Account) {
        
        // Если какой-то счет подсвечивается (в зоне реагирования)
        if let staticAccount = vm.highlitedAccount {
            
            // Выбираем тип транзакции, который получится по комбинации типов счетов
            var transactionType: TransactionType? = nil
            switch (true) {
            case draggableAccount == staticAccount: break
            case draggableAccount.type == .earnings && staticAccount.type == .regular: transactionType = .income // Доходный счет в обычный = доход
            case draggableAccount.type == .regular && staticAccount.type == .regular: transactionType = .transfer // Обычный счет в обычный = перевод
            case draggableAccount.type == .regular && staticAccount.type == .expense: transactionType = .consumption // Обычный счет в расходный = расход
            default: break
            }
            
            // Если смогли выбрать тип транзакции
            if let transactionType {
                
                // Получаем счет списания
                var accountFrom: Account? = draggableAccount

                // Если счет родительский
                if draggableAccount.isParent {

                    // Получаем первый дочерний счет (первый по serial_number считается preferred)
                    accountFrom = draggableAccount.childrenAccounts.first
                }

                // Получаем счет пополнения
                var accountTo: Account? = staticAccount

                // Если счет родительский
                if staticAccount.isParent {

                    // Получаем первый дочерний счет с валютой счета списания, иначе просто первый
                    accountTo = staticAccount.childrenAccounts.first(where: { $0.currency == accountFrom?.currency })
                        ?? staticAccount.childrenAccounts.first
                }
                
                // Если оба счета есть, независимо от предыдущей логики
                if let accountFrom = accountFrom, let accountTo = accountTo {
                    self.path.append(DraggableAccountRoute.createTransaction(transactionType, accountFrom, accountTo))
                }
            }
        }
                                     
        // Сбрасываем подсвечиваемый счет
        self.vm.highlitedAccount = nil
                                     
        // Убираем счет, который дергали
        withAnimation {
            self.vm.draggableLocation = nil
            self.vm.draggableAccount = nil
        }
    }
}

#Preview {
    DraggableAccountCircleItem(
        vm: .constant(AccountCirclesViewModel()),
        accountGroup: AccountGroup(),
        account: Account(),
        path: .constant(NavigationPath()),
        isAlreadyOpened: false
    )
}
