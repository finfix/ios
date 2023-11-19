//
//  AccountCircleView.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "Coin", category: "AccountCirclesView")

struct AccountCirclesView: View {
    
    @AppStorage("accountGroupID") var selectedAccountsGroupID: Int = 0
    @State var path = NavigationPath()
    
    var body: some View {
        AccountCirclesSubView(path: path, accountGroupID: UInt32(selectedAccountsGroupID))
    }
}

struct AccountCirclesSubView: View {
    
    @Query var accounts: [Account]
    @State var path = NavigationPath()

    init(path: NavigationPath, accountGroupID: UInt32) {
        logger.info("Инициализировали AccountCirclesListSubView")
        self.path = path
        _accounts = Query(filter: #Predicate { $0.accountGroup?.id == accountGroupID && $0.visible } )
    }
    
    let horizontalSpacing: CGFloat = 10
    
    func groupAcccounts() -> [Account] {
        logger.info("Группируем счета")
        return Account.groupAccounts(accounts)
    }
    
    var body: some View {
        let groupedAccounts = groupAcccounts()
        
        NavigationStack(path: $path) {
            VStack(spacing: 5) {
                VStack(spacing: 0) {
                    QuickStatisticView()
                    AccountGroupSelector()
                }
                Group {
                    ScrollView(.horizontal) {
                        HStack(spacing: horizontalSpacing) {
                            ForEach(groupedAccounts.filter { $0.type == .earnings }) { account in
                                AccountCircleItem(account, path: $path)
                            }
                            PlusNewAccount(accountType: .earnings)
                        }
                    }
                    
                    Divider()
                    
                    ScrollView(.horizontal) {
                        HStack(spacing: horizontalSpacing) {
                            ForEach(groupedAccounts.filter { $0.type == .regular }) { account in
                                AccountCircleItem(account, path: $path)
                            }
                            PlusNewAccount(accountType: .regular)
                        }
                    }
                    
                    Divider()
                    
                    ScrollView(.horizontal) {
                        LazyHGrid(rows: [GridItem(.adaptive(minimum: 100))], alignment: .top, spacing: horizontalSpacing) {
                            ForEach(groupedAccounts.filter { $0.type == .expense }) { account in
                                AccountCircleItem(account, path: $path)
                            }
                            PlusNewAccount(accountType: .expense)
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                .contentMargins(.horizontal, horizontalSpacing, for: .scrollContent)
                .scrollIndicators(.hidden)
                .navigationDestination(for: Account.self) { EditAccount($0) }
                .navigationDestination(for: AccountType.self) { EditAccount(accountType: $0) }
            }
            Spacer()
        }
    }
}

#Preview {
    AccountCirclesView()
        .modelContainer(previewContainer)
}
