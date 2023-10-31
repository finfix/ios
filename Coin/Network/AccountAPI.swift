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

class AccountAPI: API {
    
    func GetAccounts(req: GetAccountsRequest, completionHandler: @escaping ([Account]?, ErrorModel?) -> Void) {
        
        let (headers, err) = getBaseHeaders()
        if err != nil {
            completionHandler(nil, err)
        }
        
        // TODO: Переписать это дело под автоматическое проставление аргументов
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateFrom = dateFormatter.string(from: req.dateFrom!)
        let dateTo = dateFormatter.string(from: req.dateTo!)
        
        let params: [String: Any] = ["dateFrom": dateFrom, "dateTo": dateTo]
                
        AF.request(basePath + accountBasePath, method: .get, parameters: params, headers: headers).responseData { response in
            
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
    
    func GetAccountGroups(completionHandler: @escaping ([AccountGroup]?, ErrorModel?) -> Void) {
        
        let (headers, err) = getBaseHeaders()
        if err != nil {
            completionHandler(nil, err)
        }
                
        AF.request(basePath + accountBasePath + "/accountGroups", method: .get, headers: headers).responseData { response in
            
            let (model, error, _) = ApiHelper().dataProcessing(data: response, model: [AccountGroup].self)
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
    
    func CreateAccount(req: CreateAccountReq, completionHandler: @escaping (CreateAccountRes?, ErrorModel?) -> Void) {
        
        let (headers, err) = getBaseHeaders()
        if err != nil {
            completionHandler(nil, err)
        }
        
        AF.request(basePath + accountBasePath, method: .post, parameters: req, encoder: JSONParameterEncoder(), headers: headers).responseData { response in
            
            let (model, error, _) = ApiHelper().dataProcessing(data: response, model: CreateAccountRes.self)
            if error != nil {
                completionHandler(nil, error)
                return
            }
            if model != nil {
                completionHandler(model, nil)
            }
        }
    }
    
    func UpdateAccount(req: UpdateAccountReq, completionHandler: @escaping (ErrorModel?) -> Void) {
        
        let (headers, err) = getBaseHeaders()
        if err != nil {
            completionHandler(err)
        }
        
        AF.request(basePath + accountBasePath, method: .patch, parameters: req, encoder: JSONParameterEncoder(), headers: headers).responseData { response in
            
            let (error, _) = ApiHelper().dataProcessingWithoutParse(data: response)
            if error != nil {
                completionHandler(error)
                return
            }
            completionHandler(nil)
        }
    }
}
