//
//  AuthAPI.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import Alamofire
import SwiftUI

let authBasePath = "/auth"

class AuthAPI {
    
    func Auth(req: AuthRequest, completionHandler: @escaping (AuthResponse?, ErrorModel?) -> Void) {
        
        var headers = HTTPHeaders(
            ["DeviceID": UIDevice.current.identifierForVendor!.uuidString])
        
        // Делаем запрос на сервер
        AF.request(basePath + authBasePath + "/signIn", method: .post, parameters: req, encoder: JSONParameterEncoder(), headers: headers).responseData { response in
            
            let (model, error, _) = ApiHelper().dataProcessing(data: response, model: AuthResponse.self)
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
    
    func RefreshToken(req: RefreshTokensRequest, completionHandler: @escaping (RefreshTokensResponse?, ErrorModel?) -> Void) {
        
        var headers = HTTPHeaders(
            ["DeviceID": UIDevice.current.identifierForVendor!.uuidString])
        
        // Делаем запрос на сервер
        AF.request(basePath + authBasePath + "/refreshTokens", method: .get, parameters: req, encoder: JSONParameterEncoder(), headers: headers).responseData { response in
            
            let (model, error, _) = ApiHelper().dataProcessing(data: response, model: RefreshTokensResponse.self)
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
