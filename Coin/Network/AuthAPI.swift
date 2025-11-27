//
//  AuthAPI.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

import SwiftUI
import ProtoDefinitions
import GRPCCore
import GRPCProtobuf
import GRPCNIOTransportHTTP2

extension APIManager {
    
    func Auth(req: AuthReq) async throws -> AuthRes {
        
        let response = try await self.authClient.signIn(Auth_SignInRequest.with {
            $0.email = req.email
            $0.password = req.password
            $0.deviceID = req.device.deviceID
            $0.device = Auth_DeviceInformation.with{
                $0.deviceName = req.device.deviceName
                $0.nameOs = .ios
                $0.versionOs = req.device.versionOS
                $0.ipAddress = ""
                $0.modelName = req.device.modelName
            }
            $0.application = Auth_ApplicationInformation.with{
                $0.build = req.application.build
                $0.bundleID = req.application.bundleID
                $0.version = req.application.version
            }
        })
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }

        return AuthRes(
            id: try response.id.toUUID(),
            token: Token(
                accessToken: response.token.accessToken,
                refreshToken: response.token.refreshToken
            )
        )
    }
    
    func Register(req: RegisterReq) async throws -> AuthRes {
        
        let response = try await self.authClient.signUp(Auth_SignUpRequest.with{
            $0.name = req.name
            $0.email = req.email
            $0.password = req.password
            $0.deviceID = req.device.deviceID
            $0.device = Auth_DeviceInformation.with{
                $0.deviceName = req.device.deviceName
                $0.nameOs = .ios
                $0.versionOs = req.device.versionOS
                $0.ipAddress = ""
                $0.modelName = req.device.modelName
            }
            $0.application = Auth_ApplicationInformation.with{
                $0.build = req.application.build
                $0.bundleID = req.application.bundleID
                $0.version = req.application.version
            }
        })
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message)
        }
        
        return AuthRes(
            id: try response.id.toUUID(),
            token: Token(
                accessToken: response.token.accessToken,
                refreshToken: response.token.refreshToken
            )
        )
    }
}
