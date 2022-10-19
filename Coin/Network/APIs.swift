//
//  APIs.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import Foundation
import Alamofire

let basePath = "https://berubox.com/coin"

struct modelError: Decodable {
    var developerTextError: String
    var humanTextError: String
}

class TransactionAPI {
    
    func GetTransaction(completionHandler: @escaping ([Transaction]) -> Void) {
        
        let header: HTTPHeaders = ["Authorization": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjUyNTg5ODMyMTEsInN1YiI6IjEifQ.TneMNueJU3VT0XVGb8EGK8zyyObrmPk_x9kdh-aJDwQ"]
        
        AF.request(basePath + "/transaction", headers: header).responseDecodable(of: [Transaction].self) { response in
            
            switch response.result {
            case .success(let data):
                completionHandler(data)
            case .failure(_):
                let errorJson = try? JSONDecoder().decode(modelError.self, from: response.data!)
                print(errorJson!.humanTextError)
            }
        }
    }
    
    func CreateTransaction(req: CreateTransactionRequest, completionHandler: @escaping () -> Void) {
        
        let header: HTTPHeaders = ["Authorization": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjUyNTg5ODMyMTEsInN1YiI6IjEifQ.TneMNueJU3VT0XVGb8EGK8zyyObrmPk_x9kdh-aJDwQ"]
        
        AF.request(basePath + "/transaction", method: .post, parameters: req, encoder: JSONParameterEncoder.default, headers: header).response { response in
            
            switch response.response?.statusCode {
            case 200:
                completionHandler()
            default:
                let errorJson = try? JSONDecoder().decode(modelError.self, from: response.data!)
                print(errorJson!.humanTextError)
            }
        }
    }
    
    func UpdateTransaction (req: UpdateTransactionRequest, completionHandler: @escaping () -> Void) {
        var request = URLRequest(url: URL(string: "https://berubox.com/coin/transaction")!)
        
        let jsonRequest = try? JSONEncoder().encode(req)
        request.httpBody = jsonRequest
        request.httpMethod = "PATCH"
        request.setValue("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjUyNTg5ODMyMTEsInN1YiI6IjEifQ.TneMNueJU3VT0XVGb8EGK8zyyObrmPk_x9kdh-aJDwQ", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            if let error = error {
                print("ERROR: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Error with the response")
                return
            }
            
            if data == nil {
                completionHandler()
            }
        })
        task.resume()
    }
    
    func DeleteTransaction (id: Int, completionHandler: @escaping () -> Void) {
        var request = URLRequest(url: URL(string: "https://berubox.com/coin/transaction")!)
        
        var req = reqID(id: id)
        
        let jsonRequest = try? JSONEncoder().encode(req)
        request.httpBody = jsonRequest
        request.httpMethod = "DELETE"
        request.setValue("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjUyNTg5ODMyMTEsInN1YiI6IjEifQ.TneMNueJU3VT0XVGb8EGK8zyyObrmPk_x9kdh-aJDwQ", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            if let error = error {
                print("ERROR: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Error with the response")
                return
            }
            
            completionHandler()
            
        })
        task.resume()
    }
    
    private struct reqID: Encodable {
        var id: Int
    }
}

class UserAPI {
    
    func Login (req: LoginRequest, completionHandler: @escaping (LoginResponse) -> Void) {
        var request = URLRequest(url: URL(string: "https://berubox.com/coin/user/auth")!)
        
        let jsonRequest = try? JSONEncoder().encode(req)
        request.httpBody = jsonRequest
        request.httpMethod = "POST"
        request.setValue("iOS", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            if let error = error {
                print("Ошибка API")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Авторизация не прошла")
                return
            }
            
            if let data = data {
                let jsonResponse = try? JSONDecoder().decode(LoginResponse.self, from: data)
                completionHandler(jsonResponse!)
            }
            
        })
        task.resume()
    }
}
