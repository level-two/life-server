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

public enum ChatError : Error {
    case MessageFromAnonymousUser
    case LogFileInvalidHandler
    case InvalidChatMessagesRequest
    case InvalidChatMessage
}

struct ChatMessage : Codable {
    var messageId: Int
    var message: String
    var user: User
}

public class Chat {
    weak var sessionManager: SessionManager?
    weak var usersManager: UsersManager?
    
    var seiralQueue = DispatchQueue(label: "com.yauheni-lychkouski.life-server.chatSerialQueue")
    
    var recentMessages: [ChatMessage]
    var lastMessageId: Int
    var logIndex: [Int]
    let kNumRecentMessages = 10
    
    var logFileHandle: FileHandle
    var logIndexFileHandle: FileHandle
    
    init?(sessionManager: SessionManager, usersManager:UsersManager, documentsUrl:URL) throws {
        self.sessionManager = sessionManager
        self.usersManager = usersManager
        self.recentMessages = []
        self.lastMessageId = 0
        self.logIndex = []
        
        let logFileUrl = documentsUrl.appendingPathComponent("ChatLog.db")
        let logIndexFileUrl = documentsUrl.appendingPathComponent("ChatLogIndex.db")
        
        // Create files if they don't exist
        if FileManager.default.fileExists(atPath: logFileUrl.path) == false {
            FileManager.default.createFile(atPath: logFileUrl.path, contents: nil, attributes: nil)
        }
        if FileManager.default.fileExists(atPath: logIndexFileUrl.path) == false {
            FileManager.default.createFile(atPath: logIndexFileUrl.path, contents: nil, attributes: nil)
        }
        // Open log and index fiels for update
        self.logFileHandle = try FileHandle(forUpdating: logFileUrl)
        self.logIndexFileHandle = try FileHandle(forUpdating: logIndexFileUrl)
        
        self.sessionManager?.userLoginEvent.addHandler(target: self, handler: Chat.userLoggedIn)
        self.sessionManager?.userLogoutEvent.addHandler(target: self, handler: Chat.userLoggedOut)
        self.sessionManager?.messageEvent.addHandler(target: self, handler: Chat.gotMessage)
        
        // Load recent messages and messages index
        var logIndexFileData = logIndexFileHandle.readDataToEndOfFile()
        self.logIndex = logIndexFileData.withUnsafeBytes { (pointer: UnsafePointer<Int>) -> [Int] in
            let buffer = UnsafeBufferPointer(start: pointer, count: logIndexFileData.count/MemoryLayout<Int>.size)
            return Array<Int>(buffer)
        }
        
        self.lastMessageId = self.logIndex.count
        
        if self.lastMessageId > 0 {
            let fromId = (self.lastMessageId-kNumRecentMessages < 0) ? 0 : self.lastMessageId-kNumRecentMessages
            let seekPos = self.logIndex[fromId]
            self.logFileHandle.seek(toFileOffset: UInt64(seekPos))
            
            let logData = self.logFileHandle.readDataToEndOfFile()
            var data = "[".data(using:.utf8)!
            data.append(logData)
            data.append("]".data(using:.utf8)!)
            self.recentMessages = try JSONDecoder().decode([ChatMessage].self, from: data)
        }
    }
    
    deinit {
        self.logFileHandle.closeFile()
        self.logIndexFileHandle.closeFile()
    }
    
    public func gotMessage(connectionId:Int, userId:Int, msg:[String:Any]) {
        if let chatMessage = msg["SendChatMessage"] as? [String:Any] {
            processChatMessage(withConnection:connectionId, user:userId, chatMessage:chatMessage)
        }
        else if let recentMessagesRequest = msg["GetRecentChatMessages"] as? [String:Any] {
            processChatRecentMessagesRequest(withConnection:connectionId, user:userId, request: recentMessagesRequest)
        }
        else if let chatHistoryRequest = msg["GetChatMessages"] as? [String:Any] {
            processChatMessagesRequest(withConnection:connectionId, user:userId, request:chatHistoryRequest)
        }
    }
    
    public func userLoggedIn(userId:Int) {
        
    }
    
    public func userLoggedOut(userId:Int) {
        
    }
    
    func processChatMessage(withConnection connectionId:Int, user userId:Int, chatMessage:[String:Any]) {
        do {
            guard let user = usersManager?.getUser(withId: userId) else {
                throw ChatError.MessageFromAnonymousUser
            }
            
            guard let messageText = chatMessage["message"] as? String else {
                throw ChatError.InvalidChatMessage
            }
                
            
            let messageId = self.lastMessageId
            self.lastMessageId += 1
            
            let chatMessage = ChatMessage(messageId: messageId, message: messageText, user: user)
            
            self.recentMessages.append(chatMessage)
            if self.recentMessages.count > kNumRecentMessages {
                self.recentMessages.remove(at: 0)
            }
            
            let message = ["ChatMessage": ["id":messageId, "message":messageText, "user":["userName":user.name, "color":user.color, "userId":user.userId]]]
            sessionManager?.sendMessageBroadcast(message:message)
            
            seiralQueue.async { [weak self] in
                do {
                    try self?.storeMessage(chatMessage: chatMessage)
                }
                catch {
                    print("Failed to store message: \(error)")
                }
            }
        }
        catch {
            print("Chat: Failed to process incoming message: \(error)")
            
            // Notify client about error
            // TODO
            let message = ["ChatMessageError":["error":"Failed to process incoming message: \(error)"]]
            sessionManager?.sendMessage(connectionId:connectionId, message:message)
        }
    }
    
    func processChatRecentMessagesRequest(withConnection connectionId:Int, user userId:Int, request: [String:Any]) {
        var chatMessages: [ChatMessage]?
        if let fromId = request["fromId"] as? Int {
            seiralQueue.sync { [weak self] in
                guard let self = self else { return }
                chatMessages = try? self.getMessages(fromId: fromId, count: self.lastMessageId - fromId)
            }
        }
        else {
            chatMessages = self.recentMessages
        }
        
        let messagesArray = chatMessages?.map {
            ["id":$0.messageId, "message":$0.message, "user":["userName":$0.user.name, "color":$0.user.color, "userId":$0.user.userId]]
        }
        let message = ["ChatMessagesResponse":["chatHistory":messagesArray]]
        sessionManager?.sendMessage(connectionId:connectionId, message:message)
    }
    
    func processChatMessagesRequest(withConnection connectionId:Int, user userId:Int, request:[String:Any]) {
        do {
            guard
                let fromId = request["fromId"] as? Int,
                let count = request["count"] as? Int
                else {
                    throw ChatError.InvalidChatMessagesRequest
            }
                
            var chatMessages: [ChatMessage]?
            
            seiralQueue.sync { [weak self] in
                do {
                    chatMessages = try self?.getMessages(fromId: fromId, count: count)
                }
                catch {
                    print("Failed to get messages: \(error)")
                }
            }
            
            let messagesArray = chatMessages?.map { ["id":$0.messageId, "message":$0.message, "user":["userName":$0.user.name, "color":$0.user.color, "userId":$0.user.userId]] }
            let message = ["ChatMessagesResponse":["chatHistory":messagesArray ?? []]]
            sessionManager?.sendMessage(connectionId:connectionId, message:message)
        }
        catch {
            print("Chat: Failed to process messages request: \(error)")
            
            // Notify client about error
            let message = ["chatError": "Failed to process incoming message: \(error)"]
            sessionManager?.sendMessage(connectionId:connectionId, message:message)
        }
    }
    
    func storeMessage(chatMessage:ChatMessage) throws {
        let logFileSize = self.logFileHandle.offsetInFile
        var index = Int(logFileSize)
        self.logIndex.append(index)
        self.logIndexFileHandle.write(Data(bytes:&index, count:MemoryLayout.size(ofValue:index)))
        
        let messageJson = try JSONEncoder().encode(chatMessage)
        self.logFileHandle.write(messageJson)
        self.logFileHandle.write(",\n".data(using: .utf8)!)
    }
    
    func getMessages(fromId:Int, count:Int) throws -> [ChatMessage] {
        guard
            fromId >= 0,
            count >= 0,
            fromId < self.lastMessageId,
            fromId + count <= self.lastMessageId
        else {
            throw ChatError.InvalidChatMessagesRequest
        }
        
        let toId = fromId + count
        let fromPos = self.logIndex[fromId]
        var logData: Data
        
        if (toId == self.lastMessageId) {
            self.logFileHandle.seek(toFileOffset: UInt64(fromPos))
            logData = self.logFileHandle.readDataToEndOfFile()
        }
        else {
            let toPos = self.logIndex[toId]
            let dataLength = toPos - fromPos
            self.logFileHandle.seek(toFileOffset: UInt64(fromPos))
            logData = self.logFileHandle.readData(ofLength: Int(dataLength))
            self.logFileHandle.seekToEndOfFile()
        }
        
        var data = "[".data(using:.utf8)!
        data.append(logData)
        data.append("]".data(using:.utf8)!)
        let result = try JSONDecoder().decode([ChatMessage].self, from: data)

        return result
    }
}
