//
//  APIs.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import Foundation

class TransactionAPI {
    
    func CreateTransaction (req: CreateTransactionRequest, completionHandler: @escaping () -> Void) {
        var request = URLRequest(url: URL(string: "https://berubox.com/coin/transaction")!)
        
        let jsonRequest = try? JSONEncoder().encode(req)
        request.httpBody = jsonRequest
        request.httpMethod = "POST"
        request.setValue("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjUyNTg5ODMyMTEsInN1YiI6IjEifQ.TneMNueJU3VT0XVGb8EGK8zyyObrmPk_x9kdh-aJDwQ", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
          if let error = error {
            print("ERROR: \(error)")
            return
          }
          
          guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
            print("Error with the response, unexpected status code: \(response)")
            return
          }

          if data == nil {
            completionHandler()
          }
        })
        task.resume()
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
            print("Error with the response, unexpected status code: \(response)")
            return
          }

          if data == nil {
            completionHandler()
          }
        })
        task.resume()
      }
}
