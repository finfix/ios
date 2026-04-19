//
//  ProtoExtensions.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

import Foundation
import SwiftProtobuf
import ProtoDefinitions

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

// MARK: - Timestamp Extensions

extension Google_Protobuf_Timestamp {
    init(_ date: Date) {
        self.seconds = Int64(date.timeIntervalSince1970)
        self.nanos = Int32((date.timeIntervalSince1970.truncatingRemainder(dividingBy: 1)) * 1_000_000_000)
    }
    
    func toDate() -> Date {
        return Date(timeIntervalSince1970: TimeInterval(self.seconds) + TimeInterval(self.nanos) / 1_000_000_000)
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
