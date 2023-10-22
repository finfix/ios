//
//  API.swift
//  Coin
//
//  Created by Илья on 30.10.2022.
//

import Foundation
import Alamofire
import SwiftUI

let basePath = "https://bonavii.com"

func getBaseHeaders() -> (HTTPHeaders, ErrorModel?) {
    
    @AppStorage("accessToken") var accessToken: String?
    
    var headers = HTTPHeaders()
    var err: ErrorModel?
    
    if let accessToken = accessToken {
        headers.add(HTTPHeader(name: "Authorization", value: accessToken))
    } else {
       err = ErrorModel(developerTextError: "", humanTextError: "Пользователь не авторизован", statusCode: 8)
    }
    
    return (headers, err)
}
