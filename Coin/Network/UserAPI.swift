//
//  UserAPI.swift
//  Coin
//
//  Created by Илья on 22.10.2023.
//

import Foundation
import Alamofire

class UserAPI: API {
    
    let userBasePath = "/user"
    
    func GetCurrencies(completionHandler: @escaping ([Currency]?, ErrorModel?) -> Void) {
        
        let (headers, err) = getBaseHeaders()
        if err != nil {
            completionHandler(nil, err)
        }
                
        AF.request(basePath + userBasePath + "/currencies", method: .get, headers: headers).responseData { response in
            
            let (model, error, _) = ApiHelper().dataProcessing(data: response, model: [Currency].self)
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
    
    func GetUser(completionHandler: @escaping (User?, ErrorModel?) -> Void) {
        
        let (headers, err) = getBaseHeaders()
        if err != nil {
            completionHandler(nil, err)
        }
                
        AF.request(basePath + userBasePath + "/", method: .get, headers: headers).responseData { response in
            
            let (model, error, _) = ApiHelper().dataProcessing(data: response, model: User.self)
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
