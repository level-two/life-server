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

/*
 Expected JSON messages format
 
 For Login:
 {
    "login": {
        "userName" : "name"
    }
 }
 
 responses:
 {
     "status": true,
     "userId": "\(user.userId)",
     "message": "User \(user.name) logged in sucessfully"
 }
 
 {
    "status": false,
    "message": "Failed to login"
 }
 
 
 For user creation:
 {
    "create": {
        "userName" : "name",
        "color" : {
            "r" : 255,
            "g" : 255,
            "b" : 255
        }
    }
 }
 
 responses:
 {
    "status": true,
    "userId": "\(user.userId)",
    "message": "User \(user.name) created sucessfully"
 }
 
 {
    "status": false,
    "message": "Failed to create new user"
 }
 
 Test JSONs:
 {"create":{"userName":"abc","color":{"r":12,"g":11,"b":10}}}
 {"login":{"userName":"abc"}}
*/

import Foundation

protocol SessionManagerDelegate {
    func gotMessage(forUser userId:Int, msg:[String:Any])
    //func anonymousConnectionEstablished()
    func userLoggedIn(_ userId:Int)
    func userLoggedOut(_ userId:Int)
}

public enum SessionManagerError : Error {
    case invalidUserCreateRequest
    case invalidUserLoginRequest
}

class SessionManager : ServerDelegate {
    public var delegate = MulticastDelegate<SessionManagerDelegate>()
    
    private weak var server: Server?
    private weak var usersManager: UsersManager?
    private var userIdForConnectionId = [Int32:Int]()
    private let kNoUserId = -1
    
    // MARK: Public methods
    init(withServer server:Server, usersManager:UsersManager) {
        self.server = server
        self.server?.delegate.add(delegate:self)
        self.usersManager = usersManager
    }
    
    public func sendMessageBroadcast(dic:[String:Any]) {
        for connectionId in userIdForConnectionId.keys {
            server?.sendMessage(usingConnection: connectionId, dic: dic)
        }
    }
    
    public func sendMessageToUser(_ userId:Int, dic:[String:Any]) {
        guard let connectionId = userIdForConnectionId.first(where:{$1==userId})?.key else { return }
        server?.sendMessage(usingConnection: connectionId, dic: dic)
    }
    
    // MARK: ConnectionDelegate implementation
    public func onConnectionEstablished(withId connectionId:Int32) {
        // Create anonymous session
        userIdForConnectionId[connectionId] = kNoUserId
    }
    
    public func onConnection(withId connectionId:Int32, received message:[String:Any]) {
        if let createDic = message["create"] as? [String:Any] {
            do {
                guard let user = try createUser(withDic:createDic) else { return }
                
                let userId = user.userId
                userIdForConnectionId[connectionId] = userId
                
                // Notify client
                server?.sendMessage(usingConnection:connectionId, dic:msgDicForUserCreated(user))
                // Notify delegates
                delegate.invoke { $0.userLoggedIn(userId) }
            }
            catch {
                print("Failed to create user: \(error)")
                // Notify client about error
                server?.sendMessage(usingConnection:connectionId, dic:["status": false, "message": "Failed to create new user", "error":"\(error)"])
            }
        }
        else if let loginDic = message["login"] as? [String:Any] {
            do {
                guard let user = try loginUser(withDic:loginDic) else { return }
                
                let userId = user.userId
                userIdForConnectionId[connectionId] = userId
                
                // Notify client
                server?.sendMessage(usingConnection:connectionId, dic:msgDicForUserLoggedIn(user))
                // Notify delegates
                delegate.invoke { $0.userLoggedIn(userId) }
            }
            catch {
                print("Failed to login: \(error)")
                // Notify client about error
                server?.sendMessage(usingConnection:connectionId, dic:["status": false, "message": "Failed to login", "error":"\(error)"])
            }
        }
        else if let userId = userIdForConnectionId[connectionId] {
            delegate.invoke { $0.gotMessage(forUser: userId, msg: message) }
        }
    }
    
    public func onConnectionClosed(withId connectionId:Int32) {
        if let userId = userIdForConnectionId[connectionId] {
            userIdForConnectionId.removeValue(forKey:connectionId)
            delegate.invoke { $0.userLoggedOut(userId) }
        }
    }
    
    // MARK: Private functions
    private func createUser(withDic dic:[String:Any]) throws -> User? {
        guard
            let name = dic["userName"] as? String,
            let colorDic = dic["color"] as? [String:Any],
            let r = colorDic["r"] as? Int,
            let g = colorDic["g"] as? Int,
            let b = colorDic["b"] as? Int
            else { throw SessionManagerError.invalidUserCreateRequest }
        return try usersManager?.createUser(withName:name, withColor:Color(r:r, g:g, b:b))
    }
    
    private func msgDicForUserCreated(_ user:User) -> [String:Any] {
        return [
            "status": true,
            "userId": "\(user.userId)",
            "message": "User \(user.name) created sucessfully"
        ]
    }
    
    private func loginUser(withDic dic:[String:Any]) throws -> User? {
        guard let name = dic["userName"] as? String
            else { throw SessionManagerError.invalidUserCreateRequest }
        return try usersManager?.loginUser(withName:name)
    }
    
    private func msgDicForUserLoggedIn(_ user:User) -> [String:Any] {
        return [
            "status": true,
            "userId": "\(user.userId)",
            "message": "User \(user.name) logged in sucessfully"
        ]
    }
}
