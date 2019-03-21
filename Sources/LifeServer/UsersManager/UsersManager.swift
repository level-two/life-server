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

public enum UsersManagerError : Error {
    case UserAlreadyExists
}

public class UsersManager {
    init() {
    }
    
    func onMessage(for connectionId: Server.ConnectionId, _ message: UsersManagerMessage) {
    }
    
    let sendMessage = PublishSubject<(Server.ConnectionId, UsersManagerMessage)>()
    
    func getUserData(for userId: UserId) -> UserData? {
        return nil
    }
    
    /*
    var lastUserId: Int
    var registeredUsers: [User]
    var fileHandle: FileHandle
    
    init?(documentsUrl:URL) throws {
        lastUserId = 0 // TODO Restore previous state during server startup
        registeredUsers = []
        
        let usersFileUrl = documentsUrl.appendingPathComponent("RegisteredUsers.json")
        
        if FileManager.default.fileExists(atPath: usersFileUrl.path) == false {
            FileManager.default.createFile(atPath: usersFileUrl.path, contents: "[\n]".data(using:.utf8)!, attributes: nil)
        }
        
        fileHandle = try FileHandle(forUpdating: usersFileUrl)
        let data = fileHandle.readDataToEndOfFile()
        
        do {
            self.registeredUsers = try JSONDecoder().decode([User].self, from: data)
        }
        catch {
            fileHandle.closeFile()
            throw error
        }
        
        if let lastId = registeredUsers.last?.userId {
            self.lastUserId = lastId
        }
    }
    
    deinit {
        fileHandle.closeFile()
    }
    
    public func createUser(withName name:String, withColor color:[Int]) throws -> User {
        // return nil if user with this name exists
        if let _ = registeredUsers.first(where:{ $0.name == name }) {
            throw UsersManagerError.UserAlreadyExists
        }
        
        self.lastUserId += 1
        let userId = lastUserId
        
        let user = User(name:name, color:color, userId:userId)
        registeredUsers.append(user)
        
        let userJson = try JSONEncoder().encode(user)
        
        fileHandle.seek(toFileOffset:fileHandle.offsetInFile-1)
        fileHandle.write(userJson)
        fileHandle.write(",\n]".data(using:.utf8)!)
        
        return user
    }
    
    public func getUser(withId userId:Int) -> User? {
        return registeredUsers.first(where: { $0.userId == userId })
    }
    
    public func getUser(withName userName:String) -> User? {
        return registeredUsers.first(where: { $0.name == userName })
    }
    */
}
