//
//  API.swift
//  Coin
//
//  Created by Илья on 30.10.2022.
//

import Foundation
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "API")

class NetworkManager {
    
    static let shared = makeShared()
    
    static func makeShared() -> NetworkManager {
        return NetworkManager(authManager: .shared)
    }
    
    init(
        authManager: AuthManager
    ) {
        self.authManager = authManager
    }
    
//    private let decoder: JSONDecoder
    private let authManager: AuthManager
    
    @AppStorage("apiBasePath") var apiBasePath = defaultApiBasePath
    @AppStorage("isLogin") var isLogin: Bool = false
    
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
        case patch = "PATCH"
        case put = "PUT"
    }
    
    enum APIError: Error {
        
        case failedAuthorization
        case failedJsonEncodingRequest
        case requestError(ErrorModel?)
        case serverError(ErrorModel?)
        case responseDataError
        case failedDecodingError
    }
    
    func request(
        url urlString: String,
        method: Method,
        headers: [String: String] = [:],
        withAuthorization: Bool = true,
        query: [String: String] = [:],
        body: Encodable? = nil
    ) async throws -> Data {
        
        // Адрес
        var urlComponents = URLComponents(string: urlString)
        
        // Параметры строки
        if query != [:] {
            var urlQueryItems: [URLQueryItem] = []
            query.forEach { urlQueryItems.append(URLQueryItem(name: $0, value: $1)) }
            urlComponents?.queryItems = urlQueryItems
        }
        
        guard let url = urlComponents?.url else { throw ErrorModel(humanText: "Невалидный URL") }
        
        // Запрос
        var request = URLRequest(url: url)
        
        // Метод
        request.httpMethod = method.rawValue
        
        // Заголовки
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if withAuthorization {
            request.setValue(try await authManager.getAccessToken(), forHTTPHeaderField: "Authorization")
        }
        
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        // Тело
        if let body {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .formatted(DateFormatters.fullTime)
                request.httpBody = try encoder.encode(body)
            } catch {
                throw ErrorModel(humanText: "Ошибка при преобразовании структуры в JSON", error: "\(error)")
            }
        }
        
        var data = Data()
        var response = URLResponse()
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ErrorModel(humanText: error.localizedDescription, error: "\(error)")
        }
        let res = response as! HTTPURLResponse
        
        switch res.statusCode {
        case 200:
            return data
        default:
            throw try decodeError(data)
        }
    }
    
    func decodeError(_ data: Data) throws -> ErrorModel {
        do {
            return try JSONDecoder().decode(ErrorModel.self, from: data)
        } catch {
            throw ErrorModel(humanText: "Ошибка декодирования", error: "\(error)")
        }
    }
    
    func decode<T: Decodable>(
        _ data: Data,
        model: T.Type
    ) throws -> T {
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatters.fullTime)
        
        do {
            return try decoder.decode(model.self, from: data)
        } catch {
            throw ErrorModel(humanText: "Ошибка декодирования", error: "\(error)")
        }
    }
}
