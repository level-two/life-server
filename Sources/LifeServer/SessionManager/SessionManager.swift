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

class SessionManager {
    init() {
    }
    
    func onMessage(for userId: Server.ConnectionId, _ message: SessionManagerMessage) {
    }
    
    func getUserId(for connectionId: Server.ConnectionId) -> UserId? {
        return nil
    }
    
    func getConnectionId(for userId: UserId) -> Server.ConnectionId? {
        return nil
    }
    
    func getLoginStatus(for userId: UserId) -> Bool {
        return false
    }
    
    
    let sendMessage = PublishSubject<(Server.ConnectionId, SessionManagerMessage)>()
    
    /*
    public let messageEvent = Event3<Int, Int, [String:Any]>()
    public let userLoginEvent = Event<Int>()
    public let userLogoutEvent = Event<Int>()
    
    private weak var server: Server?
    private weak var usersManager: UsersManager?
    private var userIdForConnectionId = [Int:Int]()
    private let kNoUserId = -1
    let threadSafe = ThreadSafeHelper(withQueueName: "com.yauheni-lychkouski.life-server.sessionManagerLockQueue")
    
    // MARK: Public methods
    init(withServer server:Server, usersManager:UsersManager) {
        self.server = server
        self.server?.connectionClosedEvent.addHandler(target: self, handler: SessionManager.onConnectionClosed)
        self.server?.connectionEstablishedEvent.addHandler(target: self, handler: SessionManager.onConnectionEstablished)
        self.server?.connectionReceivedMessageEvent.addHandler(target: self, handler: SessionManager.onConnectionReceivedMessage)
        self.usersManager = usersManager
    }
    
    public func sendMessageBroadcast(message: [String:Any]) {
        server?.sendBroadcast(message: message)
    }
    
    public func sendMessage(connectionId: Int, message: [String:Any]) {
        server?.send(to: connectionId, message: message)
    }
    
    // MARK: ConnectionDelegate implementation
    public func onConnectionEstablished(connectionId:Int) {
        // Create anonymous session
        threadSafe.performAsyncBarrier { [weak self] in
            self?.userIdForConnectionId[connectionId] = self?.kNoUserId
        }
    }
    
    public func onConnectionReceivedMessage(connectionId:Int, message:[String:Any]) {
        guard let uidVsCon = safeGetUidVsCon() else { return }
        
        if let createDic = message["CreateUser"] as? [String:Any] {
            createUser(withDic:createDic, connectionId:connectionId)
        }
        else if let loginDic = message["Login"] as? [String:Any] {
            loginUser(withDic:loginDic, connectionId:connectionId)
        }
        else if let logoutDic = message["Logout"] as? [String:Any] {
            logoutUser(withDic:logoutDic, connectionId:connectionId)
        }
        else if let userId = uidVsCon[connectionId] {
            self.messageEvent.raise(with: connectionId, userId, message)
        }
    }
    
    public func onConnectionClosed(connectionId:Int) {
        var userId: Int?
        threadSafe.performSyncBarrier { [weak self] in
            userId = self?.userIdForConnectionId.removeValue(forKey:connectionId)
        }
        guard let uid = userId else { return }
        if uid != kNoUserId {
            self.userLogoutEvent.raise(with: uid)
        }
    }
    
    // MARK: Private functions
    private func safeGetUidVsCon() -> [Int:Int]? {
        var uidVsCon: [Int:Int]?
        threadSafe.performSyncConcurrent { [weak self] in
            uidVsCon = self?.userIdForConnectionId
        }
        return uidVsCon
    }
        
    private func createUser(withDic dic:[String:Any], connectionId:Int) {
        do {
            guard
                let userDic = dic["user"] as? [String:Any],
                let name = userDic["userName"] as? String,
                let color = userDic["color"] as? [Int],
                color.count == 4,
                color.filter({ $0 < 0 && $0 > 255 }).count == 0
            else {
                throw SessionManagerError.InvalidUserCreateRequest
            }
            
            guard let user = try usersManager?.createUser(withName:name, withColor:color) else {
                throw SessionManagerError.CreateUserReturnedNil
            }
            
            // Notify client
            let message = ["CreateUserResponse":["user":["userName":name, "color":color, "userId":user.userId]]]
            server?.send(to:connectionId, message:message)
        }
        catch {
            print("Failed to create new user: \(error)")
            
            // Notify client about error
            let message = ["CreateUserResponse":["error":"Failed to create new user: \(error)"]]
            server?.send(to:connectionId, message:message)
        }
    }
    
    private func loginUser(withDic dic:[String:Any], connectionId:Int) {
        do {
            guard let uidVsCon = safeGetUidVsCon() else { return }
            
            guard let userName = dic["userName"] as? String else {
                throw SessionManagerError.InvalidUserLoginRequest
            }
            
            guard let user = usersManager?.getUser(withName: userName) else {
                throw SessionManagerError.UserDoesntExist
            }
            
            let userId = user.userId
            
            guard uidVsCon[connectionId] != userId else {
                throw SessionManagerError.UserAlreadyLoggedIn
            }
            
            guard uidVsCon[connectionId] == kNoUserId else {
                throw SessionManagerError.AnotherUserAlreadyLoggedIn
            }
            
            guard uidVsCon.values.first(where:{$0 == userId}) == nil else {
                throw SessionManagerError.UserAlreadyLoggedInOnOtherConnection
            }
            
            threadSafe.performAsyncBarrier { [weak self] in
                self?.userIdForConnectionId[connectionId] = userId
            }
            
            // Notify client
            let message = ["LoginResponse":["user":["userId":user.userId, "userName":user.name, "color":user.color]]]
            
            server?.send(to:connectionId, message:message)
            
            // Send event
            self.userLoginEvent.raise(with: userId)
        }
        catch {
            print("Failed to login: \(error)")
            
            // Notify client about error
            let message = ["LoginResponse":["error":"Failed to login: \(error)"]]
            server?.send(to:connectionId, message:message)
        }
    }
    
    private func logoutUser(withDic dic:[String:Any], connectionId:Int) {
        do {
            guard let uidVsCon = safeGetUidVsCon() else { return }
            
            guard let userName = dic["userName"] as? String else {
                throw SessionManagerError.InvalidUserLogoutRequest
            }
            
            guard let connectedUserId = uidVsCon[connectionId] else {
                throw SessionManagerError.NoSessionForConnection
            }
            
            guard connectedUserId != kNoUserId else {
                throw SessionManagerError.UserIsNotLoggedIn
            }
            
            guard let user = usersManager?.getUser(withName: userName) else {
                throw SessionManagerError.UserDoesntExist
            }
            
            guard connectedUserId == user.userId else {
                throw SessionManagerError.InvalidUserIdForLogout
            }
            
            threadSafe.performAsyncBarrier { [weak self] in
                self?.userIdForConnectionId[connectionId] = self?.kNoUserId
            }
            
            // Notify client
            let message = ["LogoutResponse":["user":["userId":user.userId, "userName":user.name, "color":user.color]]]
            server?.send(to:connectionId, message:message)
            
            // Send event
            self.userLogoutEvent.raise(with: user.userId)
        }
        catch {
            print("Failed to logout: \(error)")
            
            // Notify client about error
            let message = ["LogoutResponse":["error":"Failed to logout: \(error)"]]
            server?.send(to:connectionId, message:message)
        }
    }
    */
}
