//
//  API.swift
//  Coin
//
//  Created by Илья on 30.10.2022.
//

import Foundation
import SwiftUI

class API {
    @AppStorage("basePath") var basePath: String = defaultBasePath
    
    func getBaseHeaders() throws -> [String: String] {
        @AppStorage("accessToken") var accessToken: String?
        guard let accessToken else { throw RequestError.unauthorized }
        return ["Authorization": accessToken]
    }
    
    enum RequestError: Error {
        case invalidURL
        case serverError(ErrorModel)
        case decodingError(Error)
        case encodingError(Error)
        case requestError(Error)
        case unauthorized
    }
        
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()
    
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
        case patch = "PATCH"
        case put = "PUT"
    }
        
    func request<T: Encodable, TT: Decodable>(
        url urlString: String,
        method: Method = .get,
        headers: [String: String] = [:],
        query: [String: String] = [:],
        reqModel: T,
        resModel: TT.Type
    ) async throws -> TT {
        
        // Адрес
        var urlComponents = URLComponents(string: urlString)
        
        // Параметры строки
        if query != [:] {
            var urlQueryItems: [URLQueryItem] = []
            query.forEach { urlQueryItems.append(URLQueryItem(name: $0, value: $1)) }
            urlComponents?.queryItems = urlQueryItems
        }
        
        guard let url = urlComponents?.url else { throw RequestError.invalidURL }
        
        // Запрос
        var request = URLRequest(url: url)
        
        // Метод
        request.httpMethod = method.rawValue
        
        // Заголовки
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
                
        // Тело
        do {
            request.httpBody = try JSONEncoder().encode(reqModel)
        } catch {
            throw RequestError.encodingError(error)
        }
                
        var data = Data()
        var response = URLResponse()
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw RequestError.requestError(error)
        }
        let res = response as! HTTPURLResponse
        
        switch res.statusCode {
        case 200:
            // Декодируем ответ, если передан тип
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(self.dateFormatter)
            do {
                return try decoder.decode(resModel.self, from: data)
            } catch {
                throw RequestError.decodingError(error)
            }
        default:
            let errorModel = try JSONDecoder().decode(ErrorModel.self, from: data)
            throw RequestError.serverError(errorModel)
        }
    }
    
    func request<T: Encodable>(
        url urlString: String,
        method: Method = .get,
        headers: [String: String] = [:],
        query: [String: String] = [:],
        reqModel: T
    ) async throws {
        
        // Адрес
        var urlComponents = URLComponents(string: urlString)
        
        // Параметры строки
        var urlQueryItems: [URLQueryItem] = []
        query.forEach { urlQueryItems.append(URLQueryItem(name: $0, value: $1)) }
        urlComponents?.queryItems = urlQueryItems
        
        guard let url = urlComponents?.url else { throw RequestError.invalidURL }
        
        // Запрос
        var request = URLRequest(url: url)
        
        // Метод
        request.httpMethod = method.rawValue
        
        // Заголовки
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($0, forHTTPHeaderField: $1) }
                
        // Тело
        do {
            request.httpBody = try JSONEncoder().encode(reqModel)
        } catch {
            throw RequestError.encodingError(error)
        }
                
        var data = Data()
        var response = URLResponse()
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw RequestError.requestError(error)
        }
        let res = response as! HTTPURLResponse
        
        switch res.statusCode {
        case 200:
            return
        default:
            let errorModel = try JSONDecoder().decode(ErrorModel.self, from: data)
            throw RequestError.serverError(errorModel)
        }
    }
    
    func request<TT: Decodable>(
        url urlString: String,
        method: Method = .get,
        headers: [String: String] = [:],
        query: [String: String] = [:],
        resModel: TT.Type
    ) async throws -> TT {
        
        // Адрес
        var urlComponents = URLComponents(string: urlString)
        
        // Параметры строки
        if query != [:] {
            var urlQueryItems: [URLQueryItem] = []
            query.forEach { urlQueryItems.append(URLQueryItem(name: $0, value: $1)) }
            urlComponents?.queryItems = urlQueryItems
        }
        
        guard let url = urlComponents?.url else { throw RequestError.invalidURL }
        
        // Запрос
        var request = URLRequest(url: url)
        
        // Метод
        request.httpMethod = method.rawValue
        
        // Заголовки
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
                
        var data = Data()
        var response = URLResponse()
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw RequestError.requestError(error)
        }
        let res = response as! HTTPURLResponse
        
        switch res.statusCode {
        case 200:
            // Декодируем ответ, если передан тип
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(self.dateFormatter)
            do {
                return try decoder.decode(resModel.self, from: data)
            } catch {
                throw RequestError.decodingError(error)
            }
        default:
            let errorModel = try JSONDecoder().decode(ErrorModel.self, from: data)
            throw RequestError.serverError(errorModel)
        }
    }
    
    func request(
        url urlString: String,
        method: Method = .get,
        headers: [String: String] = [:],
        query: [String: String] = [:]
    ) async throws {
        
        // Адрес
        var urlComponents = URLComponents(string: urlString)
        
        // Параметры строки
        var urlQueryItems: [URLQueryItem] = []
        query.forEach { urlQueryItems.append(URLQueryItem(name: $0, value: $1)) }
        urlComponents?.queryItems = urlQueryItems
        
        guard let url = urlComponents?.url else { throw RequestError.invalidURL }
        
        // Запрос
        var request = URLRequest(url: url)
        
        // Метод
        request.httpMethod = method.rawValue
        
        // Заголовки
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($0, forHTTPHeaderField: $1) }
                
        var data = Data()
        var response = URLResponse()
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw RequestError.requestError(error)
        }
        let res = response as! HTTPURLResponse
        
        switch res.statusCode {
        case 200:
            return
        default:
            let errorModel = try JSONDecoder().decode(ErrorModel.self, from: data)
            throw RequestError.serverError(errorModel)
        }
    }
}
