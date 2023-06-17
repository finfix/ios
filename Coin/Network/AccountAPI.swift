//
//  AccountAPI.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import Alamofire
import SwiftUI

let accountBasePath = "/account"

class AccountAPI {
    
    func GetAccounts(req: GetAccountsRequest, completionHandler: @escaping ([Account]?, ErrorModel?) -> Void) {
        
        let err = checkToken()
        if err != nil {
            completionHandler(nil, err)
            return
        }
        
        AF.request(basePath + accountBasePath, method: .get, parameters: req, headers: baseHeaders).responseData { response in
            
            let (model, error, _) = ApiHelper().dataProcessing(data: response, model: [Account].self)
            if error != nil {
                completionHandler(nil, error)
                return
            }
            if model != nil {
                completionHandler(model, nil)
                return
            }
        }
    }
}
