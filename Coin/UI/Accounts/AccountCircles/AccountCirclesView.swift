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
    @Query(sort: [SortDescriptor(\Account.serialNumber)]) var accounts: [Account]
    
    let horizontalSpacing: CGFloat = 10
    
    func groupAcccounts() -> [Account] {
        logger.info("Фильтруем и группируем счета")
        let filteredAccounts = accounts.filter {
            $0.accountGroup?.id ?? 0 == selectedAccountsGroupID &&
            $0.visible
        }
        return Account.groupAccounts(filteredAccounts)
    }
    
    var body: some View {
        let groupedAccounts = groupAcccounts()
        
        NavigationStack(path: $path) {
            VStack(spacing: 5) {
                VStack(spacing: 0) {
                    QuickStatisticView()
                    AccountGroupSelector()
                }
                VStack {
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
