//
//  OrderView.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI

struct AccountsHomeView: View {
    
    @State var vm = AccountHomeViewModel()
    @State var path = NavigationPath()
    @Binding var selectedAccountGroup: AccountGroup
    @Environment (AlertManager.self) private var alert

    @State var chooseBlurIsOpened = false

    var filteredAccounts: [Account] {
        vm.accounts.filter { $0.accountGroup == selectedAccountGroup }
    }
    
    @State var showDebts = false
    @State var currentIndex = 0
            
    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 30) {
                    VStack(spacing: 0) {
                        QuickStatisticView(selectedAccountGroup: selectedAccountGroup)
                        AccountGroupSelector(selectedAccountGroup: $selectedAccountGroup)
                    }
                    ScrollView {
                        Text("Карты и счета")
                        SnapCarouselView(spacing: 30, index: $currentIndex, items: filteredAccounts.filter { $0.visible && ($0.type == .regular)}) { account in
                            GeometryReader { proxy in
                                AccountCard(size: proxy.size, account: account)
                            }
                        }
                        .frame(height: 150)
        
                        AccountCategoryView(header: "Долги", accounts: filteredAccounts.filter { ($0.type == .debt) && ($0.visible) } )
                    }
                }
                .blur(radius: chooseBlurIsOpened ? 5 : 0)
        
                CirclesCreateTransaction(path: $path, chooseBlurIsOpened: $chooseBlurIsOpened)

            }
            .navigationDestination(for: CirclesCreateTransactionRoute.self ) { screen in
                switch screen {
                case .createTrasnaction(let transactionType):
                    EditTransaction(transactionType: transactionType, accountGroup: selectedAccountGroup)
                }
            }
        }
        .task {
            do {
                try await vm.load()
            } catch {
                alert(error)
            }
        }
    }
}

enum CirclesCreateTransactionRoute: Hashable {
    case createTrasnaction(TransactionType)
}

struct CirclesCreateTransaction: View {
    
    @Binding var path: NavigationPath
    @Binding var chooseBlurIsOpened: Bool
    
    var body: some View {
        Group {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    chooseBlurIsOpened.toggle()
                }
            } label: {
                CircleTypeTransaction(imageName: chooseBlurIsOpened ? "arrow.uturn.backward" : "plus")
            }
            if chooseBlurIsOpened {
                Button {
                    path.append(CirclesCreateTransactionRoute.createTrasnaction(.consumption))
                } label: {
                    CircleTypeTransaction(imageName: "minus")
                }
                .padding(.bottom, 90)
                
                Button {
                    path.append(CirclesCreateTransactionRoute.createTrasnaction(.income))
                } label: {
                    CircleTypeTransaction(imageName: "plus")
                }
                .padding(.trailing, 90)
                
                Button {
                    path.append(CirclesCreateTransactionRoute.createTrasnaction(.transfer))
                } label: {
                    CircleTypeTransaction(imageName: "arrow.left.arrow.right")
                }
                .padding(.trailing, 75)
                .padding(.bottom, 75)
            }
        }
        .onDisappear { chooseBlurIsOpened = false }
    }
}
    
struct CircleTypeTransaction: View {
    
    var imageName: String
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: 50, height: 50)
                .padding(20)
                .foregroundColor(.gray)
            Image(systemName: imageName)
                .foregroundColor(.black)
                .font(.system(size: 20))
        }
    }
}
    
#Preview {
    AccountsHomeView(selectedAccountGroup: .constant(AccountGroup()))
        .environment(AlertManager(handle: {_ in }))
}
