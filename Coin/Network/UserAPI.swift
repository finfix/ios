//
//  UserAPI.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import Alamofire

class UserAPI {
    
    func Auth(req: AuthRequest, completionHandler: @escaping (AuthResponse?, ErrorModel?) -> Void) {
        // Проверяем наличие accessToken
        guard let token = Defaults.accessToken else {
            completionHandler(nil, ErrorModel(developerTextError: "", humanTextError: "Пользователь не авторизован", statusCode: 8))
            return
        }
        
        // Добавляем accessToken
        let header: HTTPHeaders = ["Authorization": token]
        
        // Делаем запрос на сервер
        AF.request(basePath + "/user/auth", method: .post, parameters: req, encoder: JSONParameterEncoder(), headers: header).responseData { response in
            
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
    
    func RefreshToken(completionHandler: @escaping (Tokens?, ErrorModel?) -> Void) {
        
        // Проверяем наличие accessToken
        guard let token = Defaults.refreshToken else {
            completionHandler(nil, ErrorModel(developerTextError: "", humanTextError: "Пользователь не авторизован", statusCode: 8))
            return
        }
        
        // Делаем запрос на сервер
        AF.request(basePath + "/user/refreshTokens?token=\(token)", method: .get).responseData { response in
            
            let (model, error, _) = ApiHelper().dataProcessing(data: response, model: Tokens.self)
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
