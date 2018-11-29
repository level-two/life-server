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

public struct Color {
    var r: Int = 0
    var g: Int = 0
    var b: Int = 0
}

public struct User {
    var name: String
    var color: Color
    var userId: Int
    var isLoggedIn: Bool
}

public enum UsersManagerError : Error {
    case UserAlreadyExists
    case UserDoesntExist
    case UserAlreadyLoggedIn
}

public class UsersManager {
    var lastUserId: Int
    var registeredUsers: [User]
    
    init() {
        lastUserId = 0 // TODO Restore previous state during server startup
        registeredUsers = []
    }
    
    deinit {
        // Store lastUserId and registeredUserss
    }
    
    public func createUser(withName name:String, withColor color:Color) throws -> User {
        // return nil if user with this name exists
        if let _ = registeredUsers.first(where:{ $0.name == name }) {
            throw UsersManagerError.UserAlreadyExists
        }
        
        let userId = lastUserId
        self.lastUserId += 1
        
        let user = User(name:name, color:color, userId:userId, isLoggedIn:false)
        registeredUsers.append(user)
        return user
    }
    
    public func loginUser(withName name:String) throws -> User {
        guard let idx = registeredUsers.firstIndex(where:{ $0.name == name })
            else { throw UsersManagerError.UserDoesntExist }
        
        if registeredUsers[idx].isLoggedIn {
            throw UsersManagerError.UserAlreadyLoggedIn
        }
        
        registeredUsers[idx].isLoggedIn = true
        
        return registeredUsers[idx]
    }
}
