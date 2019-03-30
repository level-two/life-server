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
    init() {
        guard let databaseUrl = URL.applicationSupportDirectory?.appendingPathComponent("database.db")
            else { fatalError("Failed to get database path") }
        
        self.connection = SQLiteConnection(filename: databaseUrl.absoluteString)
        connection.connect() { error in
            guard let error = error else { return }
            fatalError("Failed to connect to database: \(error.localizedDescription)")
        }
    }
    
    let connection: SQLiteConnection
}

extension DatabaseManager {
    func createUsersTable() {
        //CREATE TABLE USERS(userId integer PRIMARY KEY, userName text, color integer);
    }
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
        let userName = Column("userName", String.self)
        let color = Column("color", Int32.self)
    }
    
    public func containsUser(with userId: UserId) -> Future<Void> {
        
    }

    @discardableResult
    public func store(userData: UserData) -> Future<Void> {
        
    }
    

    public func userData(with userId: UserId) -> Future<UserData> {
        // SELECT * FROM USERS WHERE USERS.userId like 3;
        let usersSchema = Users()
        let userQuery = Select(from: usersSchema).where(usersSchema.userId.like(Parameter("userIdParam")))
        let parameters: [String: Any?] = ["userIdParam": userId]
        
        let promise = Promise<UserData>()
        
        connection.execute(query: userQuery, parameters: parameters) { queryResult in
            guard let row = queryResult.asRows?.first else {
                return promise.reject(with: "No such user for given id: \(userId)")
            }
            
            guard
                let userName = row["userName"] as? String,
                let intColor = row["color"] as? Int32
            else { fatalError("Database error") }
            
            promise.resolve(with: UserData(userName: userName, userId: userId, color: .init(from: intColor)))
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
    public init(from intColor: Int32) {
        alpha = CGFloat( ((intColor >> 24) & 0xff) / 256)
        red = CGFloat( ((intColor >> 16) & 0xff) / 256)
        green = CGFloat( ((intColor >> 8) & 0xff) / 256)
        blue = CGFloat( ((intColor >> 0) & 0xff) / 256)
    }
    
    public func toInt32() -> Int32 {
        return ((alpha * 256) << 24) | ((red * 256) << 16) | ((green * 256) << 8) | ((blue * 256) << 0)
    }
}
