//
//  OrderView.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI

struct AccountsHomeView: View {
    
    @State var vm = AccountHomeViewModel()
    @Environment(PathSharedState.self) var path
    @Environment(AccountGroupSharedState.self) var selectedAccountGroup
    @Environment(AlertManager.self) private var alert
    
    @State var chooseBlurIsOpened = false
    
    var filteredAccounts: [Account] {
        vm.accounts.filter { $0.accountGroup == selectedAccountGroup.selectedAccountGroup }
    }
    
    @State var showDebts = false
    @State var currentIndex = 0
    
    @State private var activeCardIndex: Int?
    
    var body: some View {
        VStack(spacing: 30) {
            QuickStatisticView(selectedAccountGroup: selectedAccountGroup.selectedAccountGroup)
            ScrollView {
                Text("Карты и счета")
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(filteredAccounts.filter { $0.visible && ($0.type == .regular)}) { account in
                            AccountCard(account: account)
                                .containerRelativeFrame(.horizontal)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollClipDisabled()
                .scrollIndicators(.never)
                AccountCategoryView(header: "Долги", accounts: filteredAccounts.filter { ($0.type == .debt) && ($0.visible) } )
            }
            .blur(radius: chooseBlurIsOpened ? 5 : 0)
        }
        .overlay(alignment: .bottomTrailing) {
            CirclesCreateTransaction(chooseBlurIsOpened: $chooseBlurIsOpened)
        }
        .task {
            do {
                try await vm.load()
            } catch {
                alert.error(error)
            }
        }
    }
}




#Preview {
    AccountsHomeView()
        .environment(AlertManager(handle: {_ in }))
}
