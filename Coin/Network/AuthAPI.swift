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

extension Auth_DeviceInformation {
    init(_ device: DeviceInformation) {
        self.init()
        self.deviceName = device.deviceName
        self.nameOs = .ios
        self.versionOs = device.versionOS
        self.ipAddress = ""
        self.modelName = device.modelName
    }
}

extension Auth_ApplicationInformation {
    init(_ application: ApplicationInformation) {
        self.init()
        self.build = application.build
        self.bundleID = application.bundleID
        self.version = application.version
    }
}

extension Auth_SignInRequest {
    init(
        email: String,
        password: String,
        device: DeviceInformation,
        application: ApplicationInformation
    ) {
        self.init()
        self.email = email
        self.password = password
        self.deviceID = device.deviceID
        self.device = Auth_DeviceInformation(device)
        self.application = Auth_ApplicationInformation(application)
    }
}

extension Auth_SignUpRequest {
    init(
        name: String,
        email: String,
        password: String,
        device: DeviceInformation,
        application: ApplicationInformation
    ) {
        self.init()
        self.name = name
        self.email = email
        self.password = password
        self.deviceID = device.deviceID
        self.device = Auth_DeviceInformation(device)
        self.application = Auth_ApplicationInformation(application)
    }
}

extension APIManager {

    func Auth(req: AuthReq) async throws -> AuthRes {

        let request = Auth_SignInRequest(
            email: req.email,
            password: req.password,
            device: req.device,
            application: req.application
        )

        let response = try await grpcCall("SignIn", request: request) {
            try await authClient.signIn($0)
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

        let request = Auth_SignUpRequest(
            name: req.name,
            email: req.email,
            password: req.password,
            device: req.device,
            application: req.application
        )

        let response = try await grpcCall("SignUp", request: request) {
            try await authClient.signUp($0)
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
