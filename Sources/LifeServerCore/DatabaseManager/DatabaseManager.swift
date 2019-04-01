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
import SwiftKuery
import SwiftKuerySQLite

class DatabaseManager {
    init(with databaseUrl: URL = URL.applicationSupportDirectory.appendingPathComponent("LifeServer/database.db")) {
        let needInitDb = !FileManager.default.fileExists(atPath: databaseUrl.path)
        
        self.connection = SQLiteConnection(filename: databaseUrl.path)
        connection.connect() { error in
            guard error == nil else { fatalError("Failed to connect to database: \(error!.localizedDescription)") }
            guard needInitDb else { return }
            createUsersTable()
            createChatTable()
        }
    }
    
    deinit {
        connection.closeConnection()
    }
    
    let connection: SQLiteConnection
}

extension DatabaseManager: UserDatabase {
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
    
    func createUsersTable() {
        let createTableQuery = "CREATE TABLE USERS(userId integer PRIMARY KEY, userName text UNIQUE, color integer)"
        connection.execute(createTableQuery) { queryResult in
            if let error = queryResult.asError {
                fatalError("Failed to create USERS table: \(error)")
            }
        }
    }
    
    public func containsUser(with userId: UserId) -> Future<Bool> {
        let usersSchema = Users()
        let userQuery = Select(usersSchema.userId, from: usersSchema).where(usersSchema.userId.like(Parameter("userIdParam")))
        let parameters = ["userIdParam": userId] as [String: Any?]
        let promise = Promise<Bool>()
        connection.execute(query: userQuery, parameters: parameters) { queryResult in
            promise.resolve(with: queryResult.asRows?.first != nil)
        }
        return promise
    }
    
    public func containsUser(with userName: String) -> Future<Bool> {
        let usersSchema = Users()
        let userQuery = Select(usersSchema.userName, from: usersSchema).where(usersSchema.userName.like(Parameter("userNameParam")))
        let parameters = ["userNameParam": userName] as [String: Any?]
        let promise = Promise<Bool>()
        connection.execute(query: userQuery, parameters: parameters) { queryResult in
            promise.resolve(with: queryResult.asRows?.first != nil)
        }
        return promise
    }

    @discardableResult
    public func store(userData: UserData) -> Future<Void> {
        let usersSchema = Users()
        let insertQuery = Insert(into: usersSchema, values: [userData.userId, userData.userName, userData.color.toInt32])
        let promise = Promise<Void>()
        connection.execute(query: insertQuery) { queryResult in
            if case .error(let err) = queryResult {
                promise.reject(with: err)
            } else {
                promise.resolve(with: ())
            }
        }
        return promise
    }

    public func userData(with userId: UserId) -> Future<UserData> {
        let usersSchema = Users()
        let userQuery = Select(from: usersSchema).where(usersSchema.userId.like(Parameter("userIdParam")))
        let parameters = ["userIdParam": userId] as [String: Any?]
        let promise = Promise<UserData>()
        connection.execute(query: userQuery, parameters: parameters) { queryResult in
            guard let row = queryResult.asRows?.first else {
                return promise.reject(with: "No such user for given id: \(userId)")
            }
            
            guard
                let userName = row["userName"] as? String,
                let colorInt32 = row["color"] as? Int32
                else { fatalError("Database error. Failed to get row values") }
            
            let color = Color(from: UInt32(bitPattern: colorInt32))
            promise.resolve(with: UserData(userName: userName, userId: userId, color: color))
        }
        return promise
    }
    
    public func userData(with userName: String) -> Future<UserData> {
        let usersSchema = Users()
        let userQuery = Select(from: usersSchema).where(usersSchema.userName.like(Parameter("userNameParam")))
        let parameters = ["userNameParam": userName] as [String: Any?]
        let promise = Promise<UserData>()
        connection.execute(query: userQuery, parameters: parameters) { queryResult in
            guard let row = queryResult.asRows?.first else {
                return promise.reject(with: "No such user with given name: \(userName)")
            }
            
            guard
                let userId32 = row["userId"] as? Int32,
                let colorInt32 = row["color"] as? Int32
                else { fatalError("Database error. Failed to get row values") }
            
            let color = Color(from: UInt32(bitPattern: colorInt32))
            promise.resolve(with: UserData(userName: userName, userId: UserId(userId32), color: color))
        }
        return promise
    }
    
    public func numberOfRegisteredUsers() -> Future<Int> {
        let promise = Promise<Int>()
        let countQuery = "SELECT COUNT(userId) FROM USERS"
        connection.execute(countQuery) { queryResult in
            guard
                let row = queryResult.asRows?.first,
                let count = row.first?.value as? Int32
                else {
                    fatalError("Failed to get number of registered users")
                }
            
             promise.resolve(with: Int(count))
        }
        return promise
    }
}

extension DatabaseManager: ChatDatabase {
    func createChatTable() {
        //CREATE TABLE CHAT(messageId integer PRIMARY KEY, userId integer, userName text, message text);
    }
    // SELECT * FROM CHAT WHERE CHAT.messageId between 4 and 5;
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
