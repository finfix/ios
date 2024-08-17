//
//  DraggableAccountCircleItem.swift
//  Coin
//
//  Created by Илья on 28.05.2024.
//

import SwiftUI

struct DraggableAccountCircleItem: View {
    
    @ObservedObject var vm: AccountCirclesViewModel
    let accountGroup: AccountGroup
    let account: Account
    @Binding var path: NavigationPath
    @State var isChildrenOpen = false
    @Environment(\.dismiss) var dismiss
    var isAlreadyOpened: Bool = false
    
    var body: some View {
        
        VStack {
            AccountCircleItemHeader(account: account)
            AccountCircleItemCircle(account: account)
                .gesture(
                    DragGesture(coordinateSpace: .named("OuterV"))
                        .onChanged { state in
                            guard account.type != .balancing && account.type != .expense else { return }
                            vm.updateDraggableLocation(location: state.location, for: account)
                        }
                        .onEnded { state in
                            confirmDraggableDrop(for: account)
                            if isAlreadyOpened {
                                dismiss()
                            }
                        }
                )
                .gesture(
                    LongPressGesture(minimumDuration: 1)
                        .onEnded { state in
                            path.append(AccountCircleItemRoute.editAccount(account))
                            if isAlreadyOpened {
                                dismiss()
                            }
                        }
                )
                .gesture(
                    TapGesture(count: 2)
                        .onEnded {
                            if !account.childrenAccounts.isEmpty {
                                isChildrenOpen = true
                            }
                        }
                )
                .gesture(
                    TapGesture(count: 1)
                        .onEnded {
                            if isAlreadyOpened {
                                dismiss()
                            }
                            path.append(AccountCircleItemRoute.accountTransactions(account))
                        }
                )
                .overlay {
                    GeometryReader { proxy -> Color in
                        vm.initializateStaticLocations(
                            location: CGPoint(
                                x: proxy.frame(in: .named("OuterV")).midX,
                                y: proxy.frame(in: .named("OuterV")).midY
                            ),
                            for: account
                        )
                        return Color.clear
                    }
                }
                .opacity( vm.isHighligted(for: account) ? 0.6 : 1 )
                .popover(isPresented: $isChildrenOpen) {
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(account.childrenAccounts) { account in
                                DraggableAccountCircleItem(
                                    vm: vm,
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
            AccountCircleItemFooter(account: account)
        }
        .frame(width: 80)
        .opacity(account.accountingInHeader ? 1 : 0.5)
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

#Preview {
    DraggableAccountCircleItem(
        vm: AccountCirclesViewModel(),
        accountGroup: AccountGroup(),
        account: Account(),
        path: .constant(NavigationPath()),
        isAlreadyOpened: false
    )
}
