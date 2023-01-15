//
//  APIHelper.swift
//  Coin
//
//  Created by Илья on 21.10.2022.
//

import Foundation
import Alamofire

class ApiHelper {
    
    private let dateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.locale = Locale(identifier: "en_US_POSIX")
            return df
        }()
    
    func dataProcessing<T: Decodable>(data response: AFDataResponse<Data>, model: T.Type = T.self) -> (T?, ErrorModel?, Bool) {
        // Проверяем результат
        switch response.result {
            
            // Если запрос прошел
        case .success(let data):
            
            let httpCode = response.response?.statusCode
            
            // Если HTTP-код успешный
            if httpCode == 200 {
                
                // Парсим в структуру
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .formatted(self.dateFormatter)
                    let model = try decoder.decode(model.self, from: data)
                    return (model, nil, false)
                    
                    // Если не парсится, обрабатываем ошибку
                } catch {
                    print("print. Мы не смогли распарсить ответ в структуру. Ошибка: \(error)")
                    print(String(decoding: data, as: UTF8.self))
                    return (nil, ErrorModel(path:"", developerTextError: "\(error)", humanTextError: "Что-то пошло не так", statusCode: 0), false)
                }
                
                // Если код не успешный
            } else {
                
                // Парсим в структуру ошибки
                do {
                    let errorModel = try JSONDecoder().decode(ErrorModel.self, from: data)
                    return (nil, errorModel, false)
                    
                    // Если не парсится, обрабатываем ошибку
                } catch {
                    print("Мы не смогли распарсить ошибку в структуру. Проблема: \(error)")
                    print("Ошибка: \(String(decoding: data, as: UTF8.self))")
                    return(nil, ErrorModel(path:"", developerTextError: "\(error)", humanTextError: "Что-то пошло не так", statusCode: 0), false)
                }
            }
            
            // Если запрос не прошел
        case .failure(let error):
            
            // Обрабатываем ошибку
            return(nil, ErrorModel(path:"", developerTextError: "\(error)", humanTextError: "Что-то пошло не так"), false)
        }
    }
    
    func dataProcessingWithoutParse(data response: AFDataResponse<Data>) -> (ErrorModel?, Bool) {
        // Проверяем результат
        switch response.result {
            
            // Если запрос прошел
        case .success(let data):
            
            let httpCode = response.response?.statusCode
            
            // Если HTTP-код успешный
            if httpCode == 200 {
                
                return (nil, false)
                
                // Если код не успешный
            } else {
                
                // Парсим в структуру ошибки
                do {
                    let errorModel = try JSONDecoder().decode(ErrorModel.self, from: data)
                    return (errorModel, false)
                    
                    // Если не парсится, обрабатываем ошибку
                } catch {
                    print("Мы не смогли распарсить ошибку в структуру. Ошибка: \(error)")
                    return(ErrorModel(path:"", developerTextError: "\(error)", humanTextError: "Что-то пошло не так", statusCode: 0), false)
                }
            }
            
            // Если запрос не прошел
        case .failure(let error):
            
            // Обрабатываем ошибку
            return(ErrorModel(path:"", developerTextError: "\(error)", humanTextError: "Что-то пошло не так"), false)
        }
    }
}
