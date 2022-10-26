//
//  APIHelper.swift
//  Coin
//
//  Created by Илья on 21.10.2022.
//

import Foundation
import Alamofire

class ApiHelper {
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
                    let model = try JSONDecoder().decode(model.self, from: data)
                    return (model, nil, false)
                    
                    // Если не парсится, обрабатываем ошибку
                } catch {
                    print("print. Мы не смогли распарсить ответ в структуру. Ошибка: \(error)")
                    return (nil, ErrorModel(developerTextError: "\(error)", humanTextError: "Что-то пошло не так", statusCode: 0), false)
                }
                
                // Если код не успешный
            } else {
                
                // Парсим в структуру ошибки
                do {
                    let errorModel = try JSONDecoder().decode(ErrorModel.self, from: data)
                    return (nil, errorModel, false)
                    
                    // Если не парсится, обрабатываем ошибку
                } catch {
                    print("print. Мы не смогли распарсить ошибку в структуру. Ошибка: \(error)")
                    return(nil, ErrorModel(developerTextError: "\(error)", humanTextError: "Что-то пошло не так", statusCode: 0), false)
                }
            }
            
            // Если запрос не прошел
        case .failure(let error):
            
            // Обрабатываем ошибку
            return(nil, ErrorModel(developerTextError: "\(error)", humanTextError: "Что-то пошло не так"), false)
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
                    print("print. Мы не смогли распарсить ошибку в структуру. Ошибка: \(error)")
                    return(ErrorModel(developerTextError: "\(error)", humanTextError: "Что-то пошло не так", statusCode: 0), false)
                }
            }
            
            // Если запрос не прошел
        case .failure(let error):
            
            // Обрабатываем ошибку
            return(ErrorModel(developerTextError: "\(error)", humanTextError: "Что-то пошло не так"), false)
        }
    }
}
