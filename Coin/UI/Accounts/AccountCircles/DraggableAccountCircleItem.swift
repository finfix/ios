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
    
    @State private var animate = false
    @State private var time: CGFloat = CGFloat.random(in: 0...2 * .pi)
    @State private var phase: CGFloat = CGFloat.random(in: 0...2 * .pi)
    
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
                    .modifier(ShakeEffect(animatableData: vm.isEditMode ? 1 : 0))
                
                Circle()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white.opacity(0.001))
                    .gesture(
                        DragGesture(coordinateSpace: .global)
                            .onChanged { state in
                                if vm.isEditMode {
                                    // TODO: Handle drag in edit mode
                                    return
                                }
                                guard account.type != .balancing && account.type != .expense else { return }
                                vm.updateDraggableLocation(
                                    location: state.location,
                                    for: account
                                )
                            }
                            .onEnded { state in
                                if vm.isEditMode {
                                    // TODO: Handle drag end in edit mode
                                    return
                                }
                                confirmDraggableDrop(for: account)
                                if isAlreadyOpened {
                                    dismiss()
                                }
                            }
                    )
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 1)
                            .onEnded { state in
                                if vm.isEditMode {
                                    // TODO: Handle delete in edit mode
                                    return
                                }
                                path.append(AccountCircleItemRoute.editAccount(account))
                                if isAlreadyOpened {
                                    dismiss()
                                }
                            }
                    )
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded {
                                if vm.isEditMode { return }
                                if !account.childrenAccounts.isEmpty {
                                    isChildrenOpen = true
                                }
                            }
                    )
                    .gesture(
                        TapGesture(count: 1)
                            .onEnded {
                                if vm.isEditMode { return }
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
            }
            .opacity(vm.isHighligted(for: account) ? 0.6 : 1)
            .overlay(alignment: .topTrailing) {
                if vm.isEditMode {
                    Button {
                        // TODO: Handle delete
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .background(.white)
                            .clipShape(Circle())
                    }
                    .offset(x: 10, y: -10)
                }
            }
            AccountCircleItemFooter(account: account)
        }
        .frame(width: 80)
        .rotationEffect(Angle(degrees: animate ? 1 : -1))
        .offset(x: sin(time + phase) * 5, y: cos(time + phase) * 5)
        .animation(Animation.linear(duration: 0.1).repeatForever(autoreverses: true), value: animate)
        .onAppear {
            animate = true
        }
        .onChange(of: animate) { _ in
            withAnimation(Animation.linear(duration: 0.1).repeatForever(autoreverses: true)) {
                time += 0.1
            }
        }
        .opacity(account.accountingInHeader ? 1 : 0.5)
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
                    
                    // Получаем первый дочерний счет (считаем его счетом по умолчанию)
                    accountFrom = draggableAccount.childrenAccounts.first
                }
                
                // Получаем счет пополнения
                var accountTo: Account? = staticAccount
                
                // Если счет родительский
                if staticAccount.isParent {
                    
                    //Получаем первый дочерний счет (считаем его счетом по умолчанию)
                    accountTo = staticAccount.childrenAccounts.first
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

struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: sin(animatableData * .pi * 2) * 5, y: 0))
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
