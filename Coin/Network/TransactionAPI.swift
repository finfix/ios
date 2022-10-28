//
//  APIs.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import Foundation
import Alamofire
import SwiftUI

let basePath = "https://berubox.com/coin"

class TransactionAPI {
    
    // Получение транзакций
    func GetTransactions(completionHandler: @escaping ([Transaction]?, ErrorModel?) -> Void) {
        
        // Проверяем наличие accessToken
        guard let token = Defaults.accessToken else {
            completionHandler(nil, ErrorModel(path: "", developerTextError: "", humanTextError: "Пользователь не авторизован", statusCode: 8))
            return
        }
        
        // Добавляем accessToken
        let header: HTTPHeaders = ["Authorization": token, "DeviceID": UIDevice.current.identifierForVendor!.uuidString]
        
        // Делаем запрос на сервер
        AF.request(basePath + "/transaction", method: .get, headers: header).responseData { response in
            
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
        
        // Проверяем наличие accessToken
        guard let token = Defaults.accessToken else {
            completionHandler(ErrorModel(path:"", developerTextError: "", humanTextError: "Пользователь не авторизован", statusCode: 8))
            return
        }
        
        // Добавляем accessToken
        let header: HTTPHeaders = ["Authorization": token, "DeviceID": UIDevice.current.identifierForVendor!.uuidString]
        
        // Делаем запрос на сервер
        AF.request(basePath + "/transaction", method: .post, parameters: req, encoder: JSONParameterEncoder(), headers: header).responseData { response in
            
            let (error, _) = ApiHelper().dataProcessingWithoutParse(data: response)
            if error != nil {
                completionHandler(error)
                return
            }
            completionHandler(nil)
        }
    }
    
    func UpdateTransaction(req: UpdateTransactionRequest, completionHandler: @escaping (ErrorModel?) -> Void) {
        
        // Проверяем наличие accessToken
        guard let token = Defaults.accessToken else {
            completionHandler(ErrorModel(path:"", developerTextError: "", humanTextError: "Пользователь не авторизован", statusCode: 8))
            return
        }
        
        // Добавляем accessToken
        let header: HTTPHeaders = ["Authorization": token, "DeviceID": UIDevice.current.identifierForVendor!.uuidString]
        
        // Делаем запрос на сервер
        AF.request(basePath + "/transaction", method: .patch, headers: header).responseData { response in
            
            let (error, _) = ApiHelper().dataProcessingWithoutParse(data: response)
            if error != nil {
                completionHandler(error)
                return
            }
            completionHandler(nil)
        }
    }
    
    func DeleteTransaction(id: Int, completionHandler: @escaping (ErrorModel?) -> Void) {
        
        // Проверяем наличие accessToken
        guard let token = Defaults.accessToken else {
            completionHandler(ErrorModel(path:"", developerTextError: "", humanTextError: "Пользователь не авторизован", statusCode: 8))
            return
        }
        
        // Добавляем accessToken
        let header: HTTPHeaders = ["Authorization": token, "DeviceID": UIDevice.current.identifierForVendor!.uuidString]
        
        // Делаем запрос на сервер
        AF.request(basePath + "/transaction?id=\(id)", method: .delete, headers: header).responseData { response in
            
            let (error, _) = ApiHelper().dataProcessingWithoutParse(data: response)
            if error != nil {
                completionHandler(error)
                return
            }
            completionHandler(nil)
        }
    }
}
