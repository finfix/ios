//
//  AuthAPI.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import Alamofire
import SwiftUI

class AuthAPI: API {
    
    let authBasePath = "/auth"
    
    func Auth(req: AuthRequest, completionHandler: @escaping (AuthResponse?, ErrorModel?) -> Void) {
        
        let headers = HTTPHeaders(
            ["DeviceID": UIDevice.current.identifierForVendor!.uuidString])
        
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
    
    func Register(req: RegisterReq, completionHandler: @escaping (AuthResponse?, ErrorModel?) -> Void) {
        
        let headers = HTTPHeaders(
            ["DeviceID": UIDevice.current.identifierForVendor!.uuidString])
        
        AF.request(basePath + authBasePath + "/signUp", method: .post, parameters: req, encoder: JSONParameterEncoder(), headers: headers).responseData { response in
            
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
        
        let headers = HTTPHeaders(
            ["DeviceID": UIDevice.current.identifierForVendor!.uuidString])
        
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
