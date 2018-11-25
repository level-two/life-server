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

public protocol SessionManagerDelegate {
    func gotMessage(forUser userId:Int, msg:String)
    //func anonymousConnectionEstablished()
    func userLoggedIn(_ userId:Int)
    func userLoggedOut(_ userId:Int)
}

public class SessionManager : ServerDelegate {
    let json = """
{
    "login": {
        "userName" : "name"
    }

    "create": {
        "userName" : "name",
        "color" : {
            "r" : 255,
            "g" : 255,
            "b" : 255
        }
    }
}
"""
    
    weak var server: Server?
    weak var usersManager: UsersManager?
    public var delegate = MulticastDelegate<SessionManagerDelegate>()
    
    private var userIdForConnectionId = [Int:Int]()
    
    init(withServer server:Server, usersManager:UsersManager) {
        self.server = server
        self.server!.delegate.add(delegate:self)
        self.usersManager = usersManager
    }
    
    
    
    public func sendMessageBroadcast(msg:String) {
        
    }
    
    public func sendMessageToUser(_ userId:Int, msg:String) {
        
    }
    
    // MARK: ConnectionDelegate implementation
    func onConnectionEstablished(withId connectionId:Int) {
        // Create anonymous session
    }
    
    func onConnection(withId connectionId:Int, received message:[String:Any]) {
        if let createDic = message["create"] as? [String:Any] {
            if let user = tryCreateUser(withDic:createDic) {
                let userId = user.userId
                // Notify client
                server!.sendMessage(usingConnection:connectionId, dic:msgDicForUserCreated(user))
                // Notify delegates
                delegate.invoke { $0.userLoggedIn(userId) }
                
            }
            else {
                // Notify client about error
                server!.sendMessage(usingConnection:connectionId, dic:msgDicForUserCreationError())
            }
        }
        else if let loginDic = message["login"] as? [String:Any] {
            guard let user = usersManager.getUser(withName:name) else { return }
            let userId = user.userId
            
            delegate.invoke { $0.userLoggedIn(userId) }
        }
        else if let userId = getAssociatedUserId(forConnection:connectionId) {
            delegate.invoke { $0.gotMessage(forUser: userId, msg: message) }
        }
        
        // Try read LOGIN or CREATE message
        // Bind connectionId to UserId
        // If session is already established, pass the message further
    }
    
    func onConnectionClosed(withId connectionId:Int) {
        if let userId = getAssociatedUserId(forConnection:connectionId) {
            delegate.invoke { $0.userLoggedOut(userId) }
        }
    }
    
    func getAssociatedUserId(forConnection connectionId:Int) -> Int? {
        return userIdForConnectionId[connectionId]
    }
    
    func tryCreateUser(withDic dic:[String:Any]) -> User? {
        guard
            let name = dic["userName"] as? String,
            let colorDic = dic["color"] as? [String:Any],
            let r = colorDic["r"] as? Int,
            let g = colorDic["g"] as? Int,
            let b = colorDic["b"] as? Int
            else { return nil }
        
        return usersManager!.createUser(withName:name, withColor:Color(r:r, g:g, b:b))
    }
    
    func msgDicForUserCreated(user:User) -> [String:Any] {
        return [
            "status": true,
            "userId": "\(user.userId)",
            "message": "User \(user.name) created sucessfully"
        ]
    }
    
    func msgDicForUserCreationError() -> [String:Any] {
        return [
            "status": false,
            "message": "Failed to create new user"
        ]
    }
}
