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
    
    func GetAccounts(req: GetAccountsRequest, grouped: Bool, completionHandler: @escaping ([Account]?, ErrorModel?) -> Void) {
        
        let err = checkToken()
        if err != nil {
            completionHandler(nil, err)
            return
        }
        
        var path = accountBasePath
        
        if grouped {
            path += "/grouped"
        }
        AF.request(basePath + path, method: .get, parameters: req, headers: baseHeaders).responseData { response in
            
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
    
    func QuickStatistic(completionHandler: @escaping (QuickStatisticRes?, ErrorModel?) -> Void) {
        
        let err = checkToken()
        if err != nil {
            completionHandler(nil, err)
            return
        }
        
        var path = accountBasePath + "/quickStatistic"
        
        AF.request(basePath + path, method: .get, headers: baseHeaders).responseData { response in
            
            let (model, error, _) = ApiHelper().dataProcessing(data: response, model: QuickStatisticRes.self)
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
