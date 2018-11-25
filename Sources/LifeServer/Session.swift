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


public protocol UserEvents: AnyObject {
    func onUserCreated(with user: User)
    func onUserLoggedIn(with user: User)
    func onUserBecameInactive(with user: User)
    func onUser(with user: User, gotMessage message:Data)
}

public class UserSession {
    var lastUserId: UInt
    var users: [User]
    weak var delegates: [UserEvents?]
    
    init() {
        lastUserId = 0 // TODO Restore previous state during server startup
        users = []
        delegates = []
    }
    
    public func createUser(withName name:String, withColor color:Color) -> User {
        let userId = lastUserId
        self.lastUserId += 1
        
        // TODO Store user data together with ID
        let user = User(name: name, color: color, userId: userId)
        
        users.append(user)
        
        for delegate in delegates {
            delegate?.onUserCreated(with:user)
        }
        
        return user
    }
    
    public func createUser(name:String, color:Color) -> UInt {
        let userId = lastUserId
        self.lastUserId += 1
        return userId
    }
}
