// -----------------------------------------------------------------------------
//    Copyright (C) 2018 Yauheni Lychkouski.
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

public struct Color : Codable {
    var r: Int = 0
    var g: Int = 0
    var b: Int = 0
}

public struct User : Codable {
    var name: String
    var color: Color
    var userId: Int
}

public enum UsersManagerError : Error {
    case UserAlreadyExists
}

public class UsersManager {
    var lastUserId: Int
    var registeredUsers: [User]
    
    init() {
        lastUserId = 0 // TODO Restore previous state during server startup
        registeredUsers = []
        
        do {
            let url = try getStoredUsersUrl()
            
            if FileManager.default.fileExists(atPath: url.path) {
                let data = try Data(contentsOf: url)
                self.registeredUsers = try JSONDecoder().decode([User].self, from: data)
                if let lastId = registeredUsers.last?.userId {
                    self.lastUserId = lastId
                }
            }
            else {
                FileManager.default.createFile(atPath: url.path, contents: "[\n]".data(using:.utf8)!, attributes: nil)
            }
        }
        catch {
            print("Failed to load registered users list: \(error)")
        }
    }
    
    public func createUser(withName name:String, withColor color:Color) throws -> User {
        // return nil if user with this name exists
        if let _ = registeredUsers.first(where:{ $0.name == name }) {
            throw UsersManagerError.UserAlreadyExists
        }
        
        self.lastUserId += 1
        let userId = lastUserId
        
        let user = User(name:name, color:color, userId:userId)
        registeredUsers.append(user)
        
        let userJson = try JSONEncoder().encode(user)
        let url = try getStoredUsersUrl()
        
        let fileHandle = try FileHandle(forUpdating: url)
        fileHandle.seekToEndOfFile()
        fileHandle.seek(toFileOffset:fileHandle.offsetInFile-1)
        fileHandle.write(userJson)
        fileHandle.write(",\n]".data(using:.utf8)!)
        fileHandle.closeFile()
        
        return user
    }
    
    public func getUser(withId userId:Int) -> User? {
        return registeredUsers.first(where: { $0.userId == userId })
    }
    
    func getStoredUsersUrl() throws -> URL {
        #if os(Linux)
            let url = URL(fileURLWithPath: "/var/lib/life-server", isDirectory: true)
        #elseif os(macOS)
            let url = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        #endif
        return url.appendingPathComponent("RegisteredUsers.json")
    }
}
