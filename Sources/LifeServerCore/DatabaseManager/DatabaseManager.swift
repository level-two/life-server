// -----------------------------------------------------------------------------
//    Copyright (C) 2019 Yauheni Lychkouski.
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
// -----------------------------------------------------------------------------

import Foundation
import PromiseKit
import SwiftKuery
import SwiftKuerySQLite

class DatabaseManager {
    class Users: Table {
        enum Field: String {
            case userId = "userId"
            case userName = "userName"
            case color = "color"
        }

        let tableName = "Users"
        let userId = Column("userId", Int32.self, primaryKey: true, unique: true)
        let userName = Column("userName", String.self, unique: true)
        let color = Column("color", Int32.self)
    }

    class Chat: Table {
        enum Field: String {
            case messageId = "messageId"
            case userId = "userId"
            case text = "text"
        }

        let tableName = "Chat"
        let messageId = Column("messageId", Int32.self, primaryKey: true, unique: true)
        let userId = Column("userId", Int32.self)
        let text = Column("text", String.self)
    }

    init(with databaseUrl: URL) {
        let needInitDb = !FileManager.default.fileExists(atPath: databaseUrl.path)

        self.connection = SQLiteConnection(filename: databaseUrl.path)
        connection.connect { error in
            guard error == nil else { fatalError("Failed to connect to database: \(error!.localizedDescription)") }
            guard needInitDb else { return }
            createUsersTable()
            createChatTable()
        }
    }

    let connection: SQLiteConnection
}

extension DatabaseManager: UserDatabase {
    public func containsUser(with userId: UserId) -> Promise<Bool> {
        let usersSchema = Users()
        let userQuery = Select(usersSchema.userId, from: usersSchema).where(usersSchema.userId.like(Parameter("userIdParam")))
        let parameters = ["userIdParam": userId] as [String: Any?]
        return .init() { promise in
            connection.execute(query: userQuery, parameters: parameters) { queryResult in
                promise.fulfill(queryResult.asRows?.first != nil)
            }
        }
    }

    public func containsUser(with userName: String) -> Promise<Bool> {
        let usersSchema = Users()
        let userQuery = Select(usersSchema.userName, from: usersSchema).where(usersSchema.userName.like(Parameter("userNameParam")))
        let parameters = ["userNameParam": userName] as [String: Any?]
        return .init() { promise in
            connection.execute(query: userQuery, parameters: parameters) { queryResult in
                promise.fulfill(queryResult.asRows?.first != nil)
            }
        }
    }

    @discardableResult
    public func store(userData: UserData) -> Promise<UserData> {
        let usersSchema = Users()
        let insertQuery = Insert(into: usersSchema, values: [userData.userId, userData.userName, userData.color.toInt32])
        return .init() { promise in
            connection.execute(query: insertQuery) { queryResult in
                if case .error(let err) = queryResult {
                    promise.reject(err)
                } else {
                    promise.fulfill(userData)
                }
            }
        }
    }

    public func userData(with userId: UserId) -> Promise<UserData> {
        let usersSchema = Users()
        let userQuery = Select(from: usersSchema).where(usersSchema.userId.like(Parameter("userIdParam")))
        let parameters = ["userIdParam": userId] as [String: Any?]
        return .init() { promise in
            connection.execute(query: userQuery, parameters: parameters) { queryResult in
                guard let row = queryResult.asRows?.first else {
                    return promise.reject(DatabaseManagerError.noUser)
                }

                guard
                    let userName = row["userName"] as? String,
                    let colorInt32 = row["color"] as? Int32
                    else { fatalError("Database error. Failed to get row values") }

                let color = Color(from: UInt32(bitPattern: colorInt32))
                promise.fulfill(UserData(userId: userId, userName: userName, color: color))
            }
        }
    }

    public func userData(with userName: String) -> Promise<UserData> {
        let usersSchema = Users()
        let userQuery = Select(from: usersSchema).where(usersSchema.userName.like(Parameter("userNameParam")))
        let parameters = ["userNameParam": userName] as [String: Any?]

        return .init() { promise in
            connection.execute(query: userQuery, parameters: parameters) { queryResult in
                guard let row = queryResult.asRows?.first else { return promise.reject(DatabaseManagerError.noUser) }

                guard
                    let userId32 = row["userId"] as? Int32,
                    let colorInt32 = row["color"] as? Int32
                    else { fatalError("Database error. Failed to get row values") }

                let color = Color(from: UInt32(bitPattern: colorInt32))
                promise.fulfill(UserData(userId: UserId(userId32), userName: userName, color: color))
            }
        }
    }

    public func numberOfRegisteredUsers() -> Promise<Int> {
        let countQuery = "SELECT COUNT(userId) FROM USERS"

        return .init() { promise in
                connection.execute(countQuery) { queryResult in
                guard
                    let row = queryResult.asRows?.first,
                    let count = row.first?.value as? Int32
                    else { fatalError("Failed to get number of registered users") }
                promise.fulfill(Int(count))
            }
        }
    }
}

extension DatabaseManager {
    func createUsersTable() {
        let createTableQuery = "CREATE TABLE USERS(userId integer PRIMARY KEY, userName text UNIQUE, color integer)"
        connection.execute(createTableQuery) { queryResult in
            if let error = queryResult.asError {
                fatalError("Failed to create USERS table: \(error)")
            }
        }
    }
}

extension DatabaseManager: ChatDatabase {
    public func store(chatMessageData: ChatMessageData) -> Promise<ChatMessageData> {
        let schema = Chat()
        let query = Insert(into: schema, values: [chatMessageData.messageId, chatMessageData.userId, chatMessageData.text])
        return .init() { promise in
            connection.execute(query: query) { result in
                if case .error(let err) = result {
                    promise.reject(err)
                } else {
                    promise.fulfill(chatMessageData)
                }
            }
        }
    }

    public func numberOfStoredMessages() -> Promise<Int> {
        let query = "SELECT COUNT(messageId) FROM CHAT"

        return .init() { promise in
            connection.execute(query) { result in
                guard
                    let row = result.asRows?.first,
                    let count = row.first?.value as? Int32
                    else { fatalError("Failed to get number of stored messages") }
                promise.fulfill(Int(count))
            }
        }
    }

    public func messages(fromId: Int, toId: Int) -> Promise<[ChatMessageData]> {
        let schema = Chat()
        let query = Select(from: schema).where(schema.messageId.between(Parameter("fromId"), and: Parameter("toId")))
        let parameters = ["fromId": fromId, "toId": toId] as [String: Any?]

        return .init() { promise in
            connection.execute(query: query, parameters: parameters) { result in
                guard
                    let rows = result.asRows,
                    let messages = try? rows.map(ChatMessageData.init)
                    else { return promise.reject(DatabaseManagerError.failedGetChatMessages) }
                promise.fulfill(messages)
            }
        }
    }
}

extension DatabaseManager {
    func createChatTable() {
        let createTableQuery = "CREATE TABLE CHAT(messageId integer PRIMARY KEY, userId integer, text text)"
        connection.execute(createTableQuery) { queryResult in
            if let error = queryResult.asError {
                fatalError("Failed to create CHAT table: \(error)")
            }
        }
    }
}

extension Color {
    public init(from val: UInt32) {
        alpha = CGFloat((val >> 24) & 0xff) / 0xff
        red = CGFloat((val >> 16) & 0xff) / 0xff
        green = CGFloat((val >> 8) & 0xff) / 0xff
        blue = CGFloat((val >> 0) & 0xff) / 0xff
    }

    public var toInt32: Int32 {
        func comp(_ val: CGFloat, _ idx: UInt32) -> UInt32 {
            return UInt32(val * 255) << (idx * 8)
        }

        return Int32(bitPattern: comp(alpha, 3) + comp(red, 2) + comp(green, 1) + comp(blue, 0))
    }
}
