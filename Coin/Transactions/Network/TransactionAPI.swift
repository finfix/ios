//
//  ContentView.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI

/// Нужно создать класс, соответствующий протоколу ObservableObject. Соответствуя нашему классу ObservableObject, изменения в классе будут автоматически отражены в нашем представлении. Давайте создадим файл Network.swift, в котором мы будем вызывать API.
class TransactionAPI: ObservableObject {
    
    /// Нужно создать переменную пользователей @Published внутри класса. Тип переменной будет массивом пользователей. Для начала мы инициализируем переменную пустым массивом.
    @Published var transactions: [Transaction] = []
    
    /// Теперь нам нужно создать функцию getUsers, чтобы получить пользователей из API. Создайте функцию внутри класса Network.
    func getTransaction() {
        
        /// Убедимся, что у нас есть URL-адрес, прежде чем запускать следующую строку кода.
        guard let url = URL(string: "https://berubox.com/coin/transaction") else { fatalError("Missing URL") }
        
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
                        let decodedTransaction = try JSONDecoder().decode([Transaction].self, from: data)

                        /// После завершения декодирования мы присваиваем его пользовательской переменной, которую мы определили в верхней части класса.
                        self.transactions = decodedTransaction
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