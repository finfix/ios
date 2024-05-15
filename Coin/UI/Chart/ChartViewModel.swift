//
//  ChartViewModel.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import Foundation

@Observable
class ChartViewModel {
    
    let service = Service.shared
    
    var data: [Series] = []
    private var accountIDs: [UInt32] = []
    
    init(
        account: Account? = nil
    ) {
        if let account = account {
            self.accountIDs = [account.id]
            for childAccount in account.childrenAccounts {
                self.accountIDs.append(childAccount.id)
            }
        }
    }
    
    func load(accountGroupID: UInt32) async throws {
        data = try await service.getStatisticByMonth(accountGroupID: accountGroupID, accountIDs: accountIDs)
    }
}

struct Series {
    
    let name: String
    var data: [Date: Decimal]
}
