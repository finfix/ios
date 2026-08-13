//
//  ProtoExtensions.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

import Foundation
import SwiftProtobuf
import ProtoDefinitions

// MARK: - HasAccessToken Extensions
// Пустые конформансы на сгенерированные Request-типы, у которых реально есть поле
// accessToken — позволяет grpcCall подставлять токен самому (см. APIManager.swift).

extension AccountBudget_CreateAccountBudgetRequest: HasAccessToken {}
extension AccountBudget_GetAccountBudgetsRequest: HasAccessToken {}
extension AccountGroup_CreateAccountGroupRequest: HasAccessToken {}
extension AccountGroup_DeleteAccountGroupRequest: HasAccessToken {}
extension AccountGroup_GetAccountGroupsRequest: HasAccessToken {}
extension AccountGroup_UpdateAccountGroupRequest: HasAccessToken {}
extension Account_CreateAccountRequest: HasAccessToken {}
extension Account_DeleteAccountRequest: HasAccessToken {}
extension Account_GetAccountsRequest: HasAccessToken {}
extension Account_UpdateAccountRequest: HasAccessToken {}
extension AuditLog_GetAuditLogsRequest: HasAccessToken {}
extension Settings_GetCurrenciesRequest: HasAccessToken {}
extension Settings_GetIconsRequest: HasAccessToken {}
extension Sync_ConfirmSyncRequest: HasAccessToken {}
extension Sync_SyncRequest: HasAccessToken {}
extension Tag_CreateTagRequest: HasAccessToken {}
extension Tag_DeleteTagRequest: HasAccessToken {}
extension Tag_GetTagsRequest: HasAccessToken {}
extension Tag_GetTagsToTransactionsRequest: HasAccessToken {}
extension Tag_UpdateTagRequest: HasAccessToken {}
extension Transaction_CreateTransactionRequest: HasAccessToken {}
extension Transaction_DeleteTransactionRequest: HasAccessToken {}
extension Transaction_GetTransactionsRequest: HasAccessToken {}
extension Transaction_UpdateTransactionRequest: HasAccessToken {}
extension User_GetUserRequest: HasAccessToken {}
extension User_UpdateUserRequest: HasAccessToken {}

// MARK: - HasErrorField Extensions
// Пустые конформансы на сгенерированные Response-типы — у всех есть error/hasError,
// это позволяет grpcCall распаковывать ответ и бросать ErrorModel самому.

extension AccountBudget_CreateAccountBudgetResponse: HasErrorField {}
extension AccountBudget_GetAccountBudgetsResponse: HasErrorField {}
extension AccountGroup_CreateAccountGroupResponse: HasErrorField {}
extension AccountGroup_DeleteAccountGroupResponse: HasErrorField {}
extension AccountGroup_GetAccountGroupsResponse: HasErrorField {}
extension AccountGroup_UpdateAccountGroupResponse: HasErrorField {}
extension Account_CreateAccountResponse: HasErrorField {}
extension Account_DeleteAccountResponse: HasErrorField {}
extension Account_GetAccountsResponse: HasErrorField {}
extension Account_UpdateAccountResponse: HasErrorField {}
extension AuditLog_GetAuditLogsResponse: HasErrorField {}
extension Auth_SignInResponse: HasErrorField {}
extension Auth_SignUpResponse: HasErrorField {}
extension Settings_GetCurrenciesResponse: HasErrorField {}
extension Settings_GetIconsResponse: HasErrorField {}
extension Settings_GetVersionResponse: HasErrorField {}
extension Sync_ConfirmSyncResponse: HasErrorField {}
extension Sync_SyncResponse: HasErrorField {}
extension Tag_CreateTagResponse: HasErrorField {}
extension Tag_DeleteTagResponse: HasErrorField {}
extension Tag_GetTagsResponse: HasErrorField {}
extension Tag_GetTagsToTransactionsResponse: HasErrorField {}
extension Tag_UpdateTagResponse: HasErrorField {}
extension Transaction_CreateTransactionResponse: HasErrorField {}
extension Transaction_DeleteTransactionResponse: HasErrorField {}
extension Transaction_GetTransactionsResponse: HasErrorField {}
extension Transaction_UpdateTransactionResponse: HasErrorField {}
extension User_GetUserResponse: HasErrorField {}
extension User_UpdateUserResponse: HasErrorField {}

// MARK: - UUID Extensions

extension UUID {
    /// UUID → Data (16 байт)
    var data: Data {
        var uuid = self.uuid
        return withUnsafeBytes(of: &uuid) { Data($0) }
    }
}

extension Optional where Wrapped == UUID {
    var dataOrEmpty: Data {
        switch self {
        case .some(let uuid):
            return uuid.data
        case .none:
            return Data()
        }
    }
}

extension Data {
    enum UUIDError: Error {
        case invalidLength
        case invalidString
    }

    func toUUID() throws -> UUID {
        if self.count == 16 {
            return self.withUnsafeBytes { ptr in
                UUID(uuid: ptr.load(as: uuid_t.self))
            }
        } else if let string = String(data: self, encoding: .utf8),
                  let uuid = UUID(uuidString: string.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return uuid
        } else {
            throw UUIDError.invalidLength
        }
    }
}

// MARK: - ErrorCategory Extensions

extension ErrorModel.ErrorCategory {
    init(_ proto: ErrorCategory_ErrorCategory) {
        switch proto {
        case .unspecified: self = .unspecified
        case .internal: self = .internalError
        case .needToLogout: self = .needToLogout
        case .needToSync: self = .needToSync
        case .needToRefreshToken: self = .needToRefreshToken
        case .other, .UNRECOGNIZED: self = .other
        }
    }
}

// MARK: - Timestamp Extensions

extension Google_Protobuf_Timestamp {

    init(_ date: Date) {
        self.init()
        self.seconds = Int64(date.timeIntervalSince1970)
        self.nanos = Int32((date.timeIntervalSince1970.truncatingRemainder(dividingBy: 1)) * 1_000_000_000)
    }

    func toDate() -> Date {
        return Date(timeIntervalSince1970: TimeInterval(self.seconds) + TimeInterval(self.nanos) / 1_000_000_000)
    }

    // Используется только для дат-фильтров: сдвигает дату на offset таймзоны устройства,
    // чтобы сервер получал локальную дату (без учёта UTC-смещения).
    init(localFilter date: Date) {
        self.init()
        let offset = Int64(TimeZone.current.secondsFromGMT(for: date))
        self.seconds = Int64(date.timeIntervalSince1970) + offset
        self.nanos = 0
    }
}

// MARK: - TransactionType Extensions

extension TransactionType {
    
    private static let protoMap: [TransactionType: TransactionType_TransactionType] = [
        .consumption: .consumption,
        .income: .income,
        .transfer: .transfer,
        .balancing: .balancing
    ]
    
    private static var reversedProtoMap: [TransactionType_TransactionType: TransactionType] {
        return Dictionary(uniqueKeysWithValues: protoMap.map { ($1, $0) })
    }
    
    func toProto() throws -> TransactionType_TransactionType {
        guard let proto = TransactionType.protoMap[self] else {
            throw ErrorModel(humanText: "Неизвестный тип транзакции: \(self.rawValue)")
        }
        return proto
    }
    
    init(from proto: TransactionType_TransactionType) throws {
        guard let type = TransactionType.reversedProtoMap[proto] else {
            throw ErrorModel(humanText: "Неизвестный proto тип транзакции: \(proto)")
        }
        self = type
    }
}

// MARK: - AccountType Extensions

extension AccountType {
    
    private static let protoMap: [AccountType: AccountType_AccountType] = [
        .expense: .expense,
        .earnings: .earnings,
        .debt: .debt,
        .regular: .regular,
        .balancing: .balancing
    ]
    
    private static var reversedProtoMap: [AccountType_AccountType: AccountType] {
        return Dictionary(uniqueKeysWithValues: protoMap.map { ($1, $0) })
    }
    
    func toProto() throws -> AccountType_AccountType {
        guard let proto = AccountType.protoMap[self] else {
            throw ErrorModel(humanText: "Неизвестный тип счета: \(self.rawValue)")
        }
        return proto
    }
    
    init(from proto: AccountType_AccountType) throws {
        guard let type = AccountType.reversedProtoMap[proto] else {
            throw ErrorModel(humanText: "Неизвестный proto тип счета: \(proto)")
        }
        self = type
    }
}

// MARK: - AuditLogEntity Extensions

extension AuditLogEntity {

    private static let protoMap: [AuditLogEntity: AuditLog_AuditLogEntity] = [
        .transaction: .transaction,
        .account: .account,
        .accountGroup: .accountGroup,
        .tag: .tag,
        .user: .user,
        .currency: .currency
    ]

    private static var reversedProtoMap: [AuditLog_AuditLogEntity: AuditLogEntity] {
        return Dictionary(uniqueKeysWithValues: protoMap.map { ($1, $0) })
    }

    func toProto() throws -> AuditLog_AuditLogEntity {
        guard let proto = AuditLogEntity.protoMap[self] else {
            throw ErrorModel(humanText: "Неизвестная сущность аудит-лога: \(self.rawValue)")
        }
        return proto
    }

    init(from proto: AuditLog_AuditLogEntity) throws {
        guard let entity = AuditLogEntity.reversedProtoMap[proto] else {
            throw ErrorModel(humanText: "Неизвестная proto сущность аудит-лога: \(proto)")
        }
        self = entity
    }
}

// MARK: - AuditLogMethod Extensions

extension AuditLogMethod {

    private static let protoMap: [AuditLogMethod: AuditLog_AuditLogMethod] = [
        .create: .create,
        .update: .update,
        .delete: .delete
    ]

    private static var reversedProtoMap: [AuditLog_AuditLogMethod: AuditLogMethod] {
        return Dictionary(uniqueKeysWithValues: protoMap.map { ($1, $0) })
    }

    func toProto() throws -> AuditLog_AuditLogMethod {
        guard let proto = AuditLogMethod.protoMap[self] else {
            throw ErrorModel(humanText: "Неизвестный метод аудит-лога: \(self.rawValue)")
        }
        return proto
    }

    init(from proto: AuditLog_AuditLogMethod) throws {
        guard let method = AuditLogMethod.reversedProtoMap[proto] else {
            throw ErrorModel(humanText: "Неизвестный proto метод аудит-лога: \(proto)")
        }
        self = method
    }
}

