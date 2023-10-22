//
//  APIs.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import Foundation
import Alamofire
import SwiftUI

let transactionBasePath = "/transaction"

class TransactionAPI {
    
    // Получение транзакций
    func GetTransactions(req: GetTransactionRequest, completionHandler: @escaping ([Transaction]?, ErrorModel?) -> Void) {
        
        var (headers, err) = getBaseHeaders()
        if err != nil {
            completionHandler(nil, err)
        }
        
        // Делаем запрос на сервер
        AF.request(basePath + transactionBasePath, method: .get, parameters: req, headers: headers).responseData { response in
            
            let (model, error, _) = ApiHelper().dataProcessing(data: response, model: [Transaction].self)
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
    
    func CreateTransaction(req: CreateTransactionRequest, completionHandler: @escaping (ErrorModel?) -> Void) {
        
        var (headers, err) = getBaseHeaders()
        if err != nil {
            completionHandler(err)
        }
        
        // Делаем запрос на сервер
        AF.request(basePath + transactionBasePath, method: .post, parameters: req, encoder: JSONParameterEncoder(), headers: headers).responseData { response in
            
            let (error, _) = ApiHelper().dataProcessingWithoutParse(data: response)
            if error != nil {
                completionHandler(error)
                return
            }
            completionHandler(nil)
        }
    }
    
    func UpdateTransaction(req: UpdateTransactionReq, completionHandler: @escaping (ErrorModel?) -> Void) {
        
        var (headers, err) = getBaseHeaders()
        if err != nil {
            completionHandler(err)
        }
        
        // Делаем запрос на сервер
        AF.request(basePath + transactionBasePath, method: .patch, parameters: req, encoder: JSONParameterEncoder(), headers: headers).responseData { response in
            
            let (error, _) = ApiHelper().dataProcessingWithoutParse(data: response)
            if error != nil {
                completionHandler(error)
                return
            }
            completionHandler(nil)
        }
    }
    
    func DeleteTransaction(req: DeleteTransactionRequest, completionHandler: @escaping (ErrorModel?) -> Void) {
        
        var (headers, err) = getBaseHeaders()
        if err != nil {
            completionHandler(err)
        }
        
        // Делаем запрос на сервер
        AF.request(basePath + transactionBasePath, method: .delete, parameters: req, encoder: JSONParameterEncoder(), headers: headers).responseData { response in
            
            let (error, _) = ApiHelper().dataProcessingWithoutParse(data: response)
            if error != nil {
                completionHandler(error)
                return
            }
            completionHandler(nil)
        }
    }
}
