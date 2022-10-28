//
//  AccountAPI.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import Alamofire
import SwiftUI

class AccountAPI {
    
    func GetAccounts(completionHandler: @escaping ([Account]?, ErrorModel?) -> Void) {
        
        guard let token = Defaults.accessToken else {
            completionHandler(nil, ErrorModel(path:"", developerTextError: "", humanTextError: "Пользователь не авторизован", statusCode: 8))
            return
        }
        
        let header: HTTPHeaders = ["Authorization": token, "DeviceID": UIDevice.current.identifierForVendor!.uuidString]
        
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
