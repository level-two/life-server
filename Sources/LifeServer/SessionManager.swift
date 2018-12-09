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

protocol SessionManagerDelegate {
    func gotMessage(forConnection connectionId:Int32, user userId:Int, msg:[String:Any])
    //func anonymousConnectionEstablished()
    func userLoggedIn(_ userId:Int)
    func userLoggedOut(_ userId:Int)
}

enum SessionManagerError : Error {
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
    case NoSessionForConnection
}

struct MessageWrapper<T>: Codable where T:Codable {
    var type: String
    var data: T
}

class SessionManager : ServerDelegate {
    public var delegate = MulticastDelegate<SessionManagerDelegate>()
    
    private weak var server: Server?
    private weak var usersManager: UsersManager?
    private var userIdForConnectionId = [Int32:Int]()
    private let kNoUserId = -1
    let threadSafe = ThreadSafeHelper(withQueueName: "com.yauheni-lychkouski.life-server.sessionManagerLockQueue")
    
    // MARK: Public methods
    init(withServer server:Server, usersManager:UsersManager) {
        self.server = server
        self.server?.delegate.add(delegate:self)
        self.usersManager = usersManager
    }
    
    public func sendMessageBroadcast<T:Codable>(_ codableObj:T) {
        let uidVsCon = safeGetUidVsCon()
        for connectionId in uidVsCon.keys {
            server?.sendMessage(usingConnection: connectionId, codableObj: codableObj)
        }
    }
    
    public func sendMessage<T:Codable>(_ connectionId:Int32, codableObj:T) {
        //let uidVsCon = safeGetUidVsCon()
        //guard let connectionId = uidVsCon.first(where:{$1==userId})?.key else { return }
        server?.sendMessage(usingConnection: connectionId, codableObj: codableObj)
    }
    
    // MARK: ConnectionDelegate implementation
    public func onConnectionEstablished(withId connectionId:Int32) {
        // Create anonymous session
        threadSafe.performAsyncBarrier { [unowned self] in
            self.userIdForConnectionId[connectionId] = self.kNoUserId
        }
    }
    
    public func onConnection(withId connectionId:Int32, received message:[String:Any]) {
        let uidVsCon = safeGetUidVsCon()
        
        if let createDic = message["create"] as? [String:Any] {
            createUser(withDic:createDic, connectionId:connectionId)
        }
        else if let loginDic = message["login"] as? [String:Any] {
            loginUser(withDic:loginDic, connectionId:connectionId)
        }
        else if let logoutDic = message["logout"] as? [String:Any] {
            logoutUser(withDic:logoutDic, connectionId:connectionId)
        }
        else if let userId = uidVsCon[connectionId] {
            delegate.invoke { $0.gotMessage(forConnection: connectionId, user: userId, msg: message) }
        }
    }
    
    public func onConnectionClosed(withId connectionId:Int32) {
        var userId: Int?
        threadSafe.performSyncBarrier { [unowned self, connectionId] in
            userId = self.userIdForConnectionId[connectionId]
            if userId != nil {
                self.userIdForConnectionId.removeValue(forKey:connectionId)
            }
        }
        guard let uid = userId else { return }
        if uid != kNoUserId {
            delegate.invoke { $0.userLoggedOut(uid) }
        }
    }
    
    // MARK: Private functions
    private func safeGetUidVsCon() -> [Int32:Int] {
        var uidVsCon = [Int32:Int]()
        threadSafe.performSyncConcurrent { [unowned self] in
            uidVsCon = self.userIdForConnectionId
        }
        return uidVsCon
    }
        
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
            let message = MessageWrapper(type: "userCreated", data: user)
            server?.sendMessage(usingConnection:connectionId, codableObj:message)
        }
        catch {
            print("Failed to create new user: \(error)")
            
            // Notify client about error
            let message = MessageWrapper(type: "userCreationError", data: "Failed to create new user: \(error)")
            server?.sendMessage(usingConnection:connectionId, codableObj:message)
        }
    }
    
    private func loginUser(withDic dic:[String:Any], connectionId:Int32) {
        do {
            guard let userId = dic["userId"] as? Int else {
                throw SessionManagerError.InvalidUserLoginRequest
            }
            
            let uidVsCon = safeGetUidVsCon()
            
            guard uidVsCon[connectionId] != userId else {
                throw SessionManagerError.UserAlreadyLoggedIn
            }
            
            guard uidVsCon[connectionId] == kNoUserId else {
                throw SessionManagerError.AnotherUserAlreadyLoggedIn
            }
            
            guard uidVsCon.values.first(where:{$0 == userId}) == nil else {
                throw SessionManagerError.UserAlreadyLoggedInOnOtherConnection
            }
            
            guard let user = usersManager?.getUser(withId: userId) else {
                throw SessionManagerError.UserDoesntExist
            }
            
            threadSafe.performAsyncBarrier { [unowned self, userId] in
                self.userIdForConnectionId[connectionId] = userId
            }
            
            // Notify client
            let message = MessageWrapper(type: "userLoggedIn", data: user)
            server?.sendMessage(usingConnection:connectionId, codableObj:message)
            
            // Notify delegates
            delegate.invoke { $0.userLoggedIn(userId) }
        }
        catch {
            print("Failed to login: \(error)")
            
            // Notify client about error
            let message = MessageWrapper(type: "userLoginError", data: "Failed to login: \(error)")
            server?.sendMessage(usingConnection:connectionId, codableObj:message)
        }
    }
    
    private func logoutUser(withDic dic:[String:Any], connectionId:Int32) {
        do {
            guard let userId = dic["userId"] as? Int else {
                throw SessionManagerError.InvalidUserLogoutRequest
            }
            
            let uidVsCon = safeGetUidVsCon()
            guard let connectedUserId = uidVsCon[connectionId] else {
                throw SessionManagerError.NoSessionForConnection
            }
            
            guard connectedUserId != kNoUserId else {
                throw SessionManagerError.UserIsNotLoggedIn
            }
            
            guard connectedUserId == userId else {
                throw SessionManagerError.InvalidUserIdForLogout
            }
            
            guard let user = usersManager?.getUser(withId: userId) else {
                throw SessionManagerError.UserDoesntExist
            }
            
            threadSafe.performAsyncBarrier { [unowned self] in
                self.userIdForConnectionId[connectionId] = self.kNoUserId
            }
            
            // Notify client
            let message = MessageWrapper(type: "userLoggedOut", data: user)
            server?.sendMessage(usingConnection:connectionId, codableObj:message)
            
            // Notify delegates
            delegate.invoke { $0.userLoggedOut(userId) }
        }
        catch {
            print("Failed to logout: \(error)")
            
            // Notify client about error
            let message = MessageWrapper(type: "userLogoutError", data: "Failed to logout: \(error)")
            server?.sendMessage(usingConnection:connectionId, codableObj:message)
        }
    }
}
