//
//  ViewModel.swift
//  Coin
//
//  Created by Илья on 14.10.2022.
//

import SwiftUI

class AccountViewModel: ObservableObject {
    @Published var accounts = [Account]()
    
    @Published var visible = true
    @Published var accounting = true
    @Published var accountType = 1
    @Published var withoutZeroRemainder = true
    
    var todayRemainder: Int {
        
        return getTodayRemainder(sumBudget) - sum
    }
    
    func getTodayRemainder(_ remainder: Int) -> Int {
        
        let numDays = Calendar.current.range(of: .day, in: .month, for: Date())!.count
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        let day = formatter.string(from: Date())
        
        return (remainder / numDays) * Int(day)!
    }
    
    var monthRemainder: Int {
        return sumBudget - sum
    }

    var sum: Int {
        var sum = 0.0
        accountsFiltered.forEach { account in
            sum += account.remainder
        }
        return Int(sum)
    }
    
    var sumBudget: Int {
        var sum = 0.0
        accountsFiltered.forEach { account in
            sum += account.budget ?? 0
        }
        return Int(sum)
    }
    
    var types = ["earnings", "expense", "regular", "credit", "investment", "debt"]
    
    var accountsFiltered: [Account]  {
        
        var subfiltered = accounts
        
        if visible {
            subfiltered = subfiltered.filter { $0.visible }
        }
        
        if accounting {
            subfiltered = subfiltered.filter { $0.accounting }
        }
        
        if accountType != 0 {
            subfiltered = subfiltered.filter { $0.typeSignatura == types[accountType] }
        }
        
        if withoutZeroRemainder {
            subfiltered = subfiltered.filter { $0.remainder != 0 }
        }
        
       return subfiltered.sorted { $0.remainder > $1.remainder }
    }
    
    func getAccount() {
        
        /// Убедимся, что у нас есть URL-адрес, прежде чем запускать следующую строку кода.
        guard let url = URL(string: "https://berubox.com/coin/account?period=month") else { fatalError("Missing URL") }
        
        /// С помощью этого URL-адреса мы создаем URLRequest и передаем его в нашу dataTask.
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjUyNTg5ODMyMTEsInN1YiI6IjEifQ.TneMNueJU3VT0XVGb8EGK8zyyObrmPk_x9kdh-aJDwQ", forHTTPHeaderField: "Authorization")
        
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }
            
            guard let response = response as? HTTPURLResponse else { return }
            
            /// Мы следим за тем, чтобы ошибки не было и получили ответ
            if response.statusCode == 200 {
                
                /// Проверяем, что у нас есть данные.
                guard let data = data else { return }
                
                DispatchQueue.main.async {
                    do {
                        
                        /// Декодируем получаемые данные в формате JSON, используя JSONDecoder, и декодируем данные в массив пользователей.
                        let decodedAccount = try JSONDecoder().decode([Account].self, from: data)
                        
                        /// После завершения декодирования мы присваиваем его пользовательской переменной, которую мы определили в верхней части класса.
                        self.accounts = decodedAccount
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            } else {
                
                guard let data = data else { return }
                
                DispatchQueue.main.async {
                    do {
                        
                        /// Декодируем получаемые данные в формате JSON, используя JSONDecoder, и декодируем данные в массив пользователей.
                        let decodedError = try JSONDecoder().decode(ModelError.self, from: data)
                        
                        /// После завершения декодирования мы присваиваем его пользовательской переменной, которую мы определили в верхней части класса.
                        print(decodedError.developerTextError)
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }
        
        /// Возобновляем dataTask с помощью dataTask.resume().
        dataTask.resume()
    }
}


