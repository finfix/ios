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

class UserAPI {
    
    func Auth(req: AuthRequest, completionHandler: @escaping (AuthResponse?, ErrorModel?) -> Void) {
        
        // Делаем запрос на сервер
        AF.request(basePath + authBasePath + "/signIn", method: .post, parameters: req, encoder: JSONParameterEncoder(), headers: baseHeaders).responseData { response in
            
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
        
        // Проверяем наличие refreshToken
        guard let token = Defaults.refreshToken else {
            completionHandler(nil, ErrorModel(developerTextError: "", humanTextError: "Пользователь не авторизован", statusCode: 8))
            return
        }
        
        // Делаем запрос на сервер
        AF.request(basePath + authBasePath + "/refreshTokens", method: .get, parameters: req, encoder: JSONParameterEncoder(), headers: baseHeaders).responseData { response in
            
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
