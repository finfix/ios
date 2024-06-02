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

class API {
    @AppStorage("apiBasePath") var apiBasePath = defaultApiBasePath
    @AppStorage("refreshToken") var refreshToken: String?
    @AppStorage("accessToken") var accessToken: String?
    @AppStorage("isLogin") var isLogin: Bool = false

    func getBaseHeaders() throws -> [String: String] {
        guard let accessToken else {
            isLogin = false
            throw ErrorModel(humanTextError: "AccessToken отсутствует")
        }
        return ["Authorization": accessToken]
    }
    
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
        case patch = "PATCH"
        case put = "PUT"
    }
        
    func request(
        url urlString: String,
        method: Method,
        headers: [String: String] = [:],
        query: [String: String] = [:],
        body: Encodable? = nil,
        handleUnauthorized: Bool = true
    ) async throws -> Data {
        
        // Адрес
        var urlComponents = URLComponents(string: urlString)
        
        // Параметры строки
        if query != [:] {
            var urlQueryItems: [URLQueryItem] = []
            query.forEach { urlQueryItems.append(URLQueryItem(name: $0, value: $1)) }
            urlComponents?.queryItems = urlQueryItems
        }
        
        guard let url = urlComponents?.url else { throw ErrorModel(humanTextError: "Невалидный URL") }
        
        // Запрос
        var request = URLRequest(url: url)
        
        // Метод
        request.httpMethod = method.rawValue
        
        // Заголовки
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
                
        // Тело
        if let body {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .formatted(DateFormatters.fullTime)
                request.httpBody = try encoder.encode(body)
            } catch {
                throw ErrorModel(humanTextError: "Ошибка при преобразовании структуры в JSON", developerTextError: "\(error)")
            }
        }
                
        return try await httpRequest(
            request: request,
            handleUnauthorized: handleUnauthorized
        )
    }
    
    private func httpRequest(
        request: URLRequest,
        handleUnauthorized: Bool
    ) async throws -> Data {
        var request = request
        
        var data = Data()
        var response = URLResponse()
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ErrorModel(humanTextError: error.localizedDescription, developerTextError: "\(error)")
        }
        let res = response as! HTTPURLResponse
        
        switch res.statusCode {
        case 200:
            return data
        case 401:
            guard handleUnauthorized else {
                isLogin = false
                throw try decodeError(data)
            }
            
            request.setValue(try await getNewTokens(), forHTTPHeaderField: "Authorization")
            
            return try await httpRequest(
                request: request,
                handleUnauthorized: false
            )
            
        default:
            throw try decodeError(data)
        }
    }
    
    private func getNewTokens() async throws -> String {
        guard let refreshToken else {
            throw ErrorModel(humanTextError: "Refresh token отсутствует")
        }
        let tokens = try await AuthAPI().RefreshToken(req: RefreshTokensReq(
            token: refreshToken,
            application: try getApplicationInformation(),
            device: getDeviceInformation()
        ))
        self.refreshToken = tokens.refreshToken
        self.accessToken = tokens.accessToken
        return tokens.accessToken
    }
    
    private func decodeError(
        _ data: Data
    ) throws -> ErrorModel {
        do {
            return try JSONDecoder().decode(ErrorModel.self, from: data)
        } catch {
            throw ErrorModel(humanTextError: "Ошибка декодирования", developerTextError: "\(error)")
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
            throw ErrorModel(humanTextError: "Ошибка декодирования", developerTextError: "\(error)")
        }
    }
}
