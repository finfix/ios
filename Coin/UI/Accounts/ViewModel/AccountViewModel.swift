//
//  ViewModel.swift
//  Coin
//
//  Created by Илья on 14.10.2022.
//

import SwiftUI

class AccountViewModel: ObservableObject {
    
    @Environment(\.realm) var realm

    @Published var visible = true
    @Published var accounting = true
    @Published var accountType = 1
    @Published var withoutZeroRemainder = true
    @Published var selectedAccountGroupID: Int = 0
    
    // Возможные типы счетов
    var types = ["earnings", "expense", "regular", "credit", "investment", "debt"]
    
    func getAccount(_ settings: AppSettings) {
            
            // Если в базе данных нет транзакций
            if self.realm.objects(Account.self).isEmpty {
                
                // Делаем запрос на сервер
                AccountAPI().GetAccounts() { response, error in
                    if let err = error {
                        settings.showErrorAlert(error: err)
                    } else if let response = response {
                        
                        // Добавляем все транзакции с сервера в базу данных
                        try? self.realm.write {
                            self.realm.add(response)
                        }
                    }
                }
                
                // Если в базе данных есть транзакции
            } else {
                
                // Запрашиваем с сервера последние изменения
                UserAPI().GetChanges() { response, error in
                    if let err = error {
                        settings.showErrorAlert(error: err)
                        
                        // И добавляем изменения в бд
                    } else if let response = response {
                        
                        // Добавляем транзакции
                        if let Accounts = response.created?.transactions {
                            try? self.realm.write {
                                self.realm.add(Accounts)
                            }
                        }
                        
                        // Изменяем транзакции
                        if let Accounts = response.updated?.transactions {
                            for Account in Accounts {
                                try? self.realm.write({
                                    self.realm.add(Account, update: .modified)
                                })
                            }
                        }
                        
                        // Удаляем транзакции
                        if let ids = response.deleted?.transactionsID {
                            try? self.realm.write {
                                self.realm.delete(self.realm.objects(Account.self).filter("id in (%@)", ids))
                            }
                        }
                        
                        // Добавляем счета
                        if let accounts = response.created?.accounts {
                            try? self.realm.write {
                                self.realm.add(accounts)
                            }
                        }
                        
                        // Изменяем счета
                        if let accounts = response.updated?.accounts {
                            for account in accounts {
                                try? self.realm.write({
                                    self.realm.add(account, update: .modified)
                                })
                            }
                        }
                        
                        // Удаляем счета
                        if let ids = response.deleted?.accoutnsID {
                            try? self.realm.write {
                                self.realm.delete(self.realm.objects(Account.self).filter("id in (%@)", ids))
                            }
                        }
                    }
                }
            }
        }
}


