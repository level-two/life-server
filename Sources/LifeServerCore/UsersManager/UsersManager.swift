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
import RxSwift
import RxCocoa
import SwiftKuery
import SwiftKuerySQLite

public enum UsersManagerError: Error {
    case userAlreadyExists
}

public class UsersManager {
    init() throws {
        lastUserId = 0
        registeredUsers = []

        let usersFileUrl = URL.applicationDocumentsDirectory.appendingPathComponent("RegisteredUsers.json")
        
        if FileManager.default.fileExists(atPath: usersFileUrl.path) == false {
            let result = FileManager.default.createFile(atPath: usersFileUrl.path,
                                           contents: "[\n]".data(using: .utf8)!,
                                           attributes: nil)
            guard result else { throw "Failed to create file: \(usersFileUrl.description)" }
        }

        do {
            fileHandle = try FileHandle(forUpdating: usersFileUrl)
        } catch {
            throw "Failed to open \(usersFileUrl.description) for update"
        }

        let data = fileHandle.readDataToEndOfFile()

        do {
            self.registeredUsers = try JSONDecoder().decode([UserData].self, from: data)
        } catch {
            fileHandle.closeFile()
            throw "Failed to decode registered users: \(error)"
        }

        if let lastId = registeredUsers.last?.userId {
            self.lastUserId = lastId
        }
    }

    deinit {
        fileHandle.closeFile()
    }

    public func createUser(with userName: String, and color: Color) throws -> UserData {
        guard registeredUsers.allSatisfy({ $0.userName != userName }) else {
            throw UsersManagerError.userAlreadyExists
        }

        self.lastUserId += 1
        let userId = lastUserId

        let user = UserData(userName: userName, userId: userId, color: color)

        // Store to DB
        registeredUsers.append(user)

        let userJson = try JSONEncoder().encode(user)

        fileHandle.seek(toFileOffset: fileHandle.offsetInFile-1)
        fileHandle.write(userJson)
        fileHandle.write(",\n]".data(using: .utf8)!)

        return user
    }

    var lastUserId: Int
    var registeredUsers: [UserData]
    var fileHandle: FileHandle
}

extension UsersManager: UserDataProvider {
    public func userData(for userId: UserId) -> UserData? {
        return registeredUsers.first(where: { $0.userId == userId })
    }
}
