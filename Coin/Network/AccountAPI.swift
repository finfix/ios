//
//  AccountAPI.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import Alamofire

class AccountAPI {
    
    func GetAccounts(completionHandler: @escaping ([Account]?, ErrorModel?) -> Void) {
        
        guard let token = Defaults.accessToken else {
            completionHandler(nil, ErrorModel(developerTextError: "", humanTextError: "Пользователь не авторизован", statusCode: 8))
            return
        }
        
        let header: HTTPHeaders = ["Authorization": token]
        
        AF.request(basePath + "/account?period=month", method: .get, headers: header).responseData { response in
            
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
