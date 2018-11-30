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
    case InvalidUserCreateRequest
    case InvalidUserLoginRequest
    case InvalidUserLogoutRequest
    case UserDoesntExist
    case CreateUserReturnedNil
    case UserIsNotLoggedIn
    case UserAlreadyLoggedIn
    case UserAlreadyLoggedInOnOtherConnection
    case AnotherUserAlreadyLoggedIn
    case UserAlreadyLoggedOut
    case InvalidUserIdForLogout
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
            createUser(withDic:createDic, connectionId:connectionId)
        }
        else if let loginDic = message["login"] as? [String:Any] {
            loginUser(withDic:loginDic, connectionId:connectionId)
        }
        else if let logoutDic = message["logout"] as? [String:Any] {
            logoutUser(withDic:logoutDic, connectionId:connectionId)
        }
        else if let userId = userIdForConnectionId[connectionId] {
            delegate.invoke { $0.gotMessage(forUser: userId, msg: message) }
        }
    }
    
    public func onConnectionClosed(withId connectionId:Int32) {
        guard let userId = userIdForConnectionId[connectionId] else { return }
        if userId != kNoUserId {
            delegate.invoke { $0.userLoggedOut(userId) }
        }
        userIdForConnectionId.removeValue(forKey:connectionId)
    }
    
    // MARK: Private functions
    private func createUser(withDic dic:[String:Any], connectionId:Int32) {
        do {
            guard
                let name = dic["userName"] as? String,
                let colorDic = dic["color"] as? [String:Any],
                let r = colorDic["r"] as? Int,
                let g = colorDic["g"] as? Int,
                let b = colorDic["b"] as? Int
                else {
                    throw SessionManagerError.InvalidUserCreateRequest
                }
            
            guard let user = try usersManager?.createUser(withName:name, withColor:Color(r:r, g:g, b:b)) else {
                throw SessionManagerError.CreateUserReturnedNil
            }
            
            // Notify client
            server?.sendMessage(usingConnection:connectionId,
                                dic:["status":true, "userId":"\(user.userId)", "message":"User \(user.name) created sucessfully"])
        }
        catch {
            print("Failed to create new user: \(error)")
            
            // Notify client about error
            server?.sendMessage(usingConnection:connectionId, dic:["status":false, "message":"Failed to create new user: \(error)"])
        }
    }
    
    private func loginUser(withDic dic:[String:Any], connectionId:Int32) {
        do {
            guard let userId = dic["userId"] as? Int else {
                throw SessionManagerError.InvalidUserLoginRequest
            }
            
            if userIdForConnectionId[connectionId] == userId {
                throw SessionManagerError.UserAlreadyLoggedIn
            }
            
            if userIdForConnectionId[connectionId] != kNoUserId {
                throw SessionManagerError.AnotherUserAlreadyLoggedIn
            }
            
            if let _ = userIdForConnectionId.values.first(where:{$0 == userId}) {
                throw SessionManagerError.UserAlreadyLoggedInOnOtherConnection
            }
            
            guard let user = usersManager?.getUser(withId: userId) else {
                throw SessionManagerError.UserDoesntExist
            }
            
            userIdForConnectionId[connectionId] = userId
            
            // Notify client
            server?.sendMessage(usingConnection:connectionId,
                                dic:["status":true, "userId":"\(userId)", "message":"User \(user.name) logged in sucessfully"])
            
            // Notify delegates
            delegate.invoke { $0.userLoggedIn(userId) }
        }
        catch {
            print("Failed to login: \(error)")
            
            // Notify client about error
            server?.sendMessage(usingConnection:connectionId,
                                dic:["status": false, "message": "Failed to login: \(error)"])
        }
    }
    
    private func logoutUser(withDic dic:[String:Any], connectionId:Int32) {
        do {
            guard let userId = dic["userId"] as? Int else {
                throw SessionManagerError.InvalidUserLogoutRequest
            }
            
            let connectedUserId = userIdForConnectionId[connectionId]!
            
            if connectedUserId == kNoUserId {
                throw SessionManagerError.UserIsNotLoggedIn
            }
            
            if connectedUserId != userId {
                throw SessionManagerError.InvalidUserIdForLogout
            }
            
            userIdForConnectionId[connectionId] = kNoUserId
            
            // Notify client
            server?.sendMessage(usingConnection:connectionId,
                                dic:["status":true, "userId":"\(userId)","message": "User logged out sucessfully"])
            
            // Notify delegates
            delegate.invoke { $0.userLoggedOut(userId) }
        }
        catch {
            print("Failed to logout: \(error)")
            
            // Notify client about error
            server?.sendMessage(usingConnection:connectionId,
                                dic:["status":false, "message":"Failed to logout: \(error)"])
        }
    }
}
