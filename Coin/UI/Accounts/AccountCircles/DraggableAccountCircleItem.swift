//
//  DraggableAccountCircleItem.swift
//  Coin
//
//  Created by Илья on 28.05.2024.
//

import SwiftUI

struct DraggableAccountCircleItem: View {
    
    @ObservedObject var vm: AccountCirclesViewModel
    let account: Account
    @Binding var path: NavigationPath
    @State var isChildrenOpen = false
    @Environment(\.dismiss) var dismiss
    var isAlreadyOpened: Bool = false
    
    var body: some View {
        AccountCircleItem(account)
            .frame(width: 80)
            .gesture(
                DragGesture(coordinateSpace: .named("OuterV"))
                    .onChanged { state in
                        guard account.type != .balancing && account.type != .expense else { return }
                        guard !account.isParent else { return }
                        vm.updateDraggableLocation(location: state.location, for: account)
                    }
                    .onEnded { state in
                        vm.confirmDraggableDrop(for: account)
                        vm.removeChildrenPositions(account: account)
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
                        vm.removeChildrenPositions(account: account)
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
                            vm.removeChildrenPositions(account: account)
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
}

#Preview {
    DraggableAccountCircleItem(
        vm: AccountCirclesViewModel(),
        account: Account(),
        path: .constant(NavigationPath()),
        isAlreadyOpened: false
    )
}
