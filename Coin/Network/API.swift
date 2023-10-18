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

func getBaseHeaders() -> HTTPHeaders {
    return HTTPHeaders(["Authorization": Defaults.accessToken ?? ""])
}

func checkToken() -> (ErrorModel?){
    if Defaults.accessToken == nil {
        return ErrorModel(developerTextError: "", humanTextError: "Пользователь не авторизован", statusCode: 8)
    }
    return nil
}
