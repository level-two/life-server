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
}

struct ChatMessage : Codable {
    var messageId: Int
    var userName: String
    var message: String
}

struct BroadcastChatMessage : Codable {
    var chatMessage: ChatMessage
}

struct RecentChatMessages : Codable {
    var status: Bool
    var recentMessages: [ChatMessage]
}

struct ChatErrorResponse: Codable {
    var status: Bool
    var message: String
}

public class Chat : SessionManagerDelegate {
    weak var sessionManager: SessionManager?
    weak var usersManager: UsersManager?
    
    var seiralQueue = DispatchQueue(label: "com.yauheni-lychkouski.life-server.chatSerialQueue")
    
    var recentMessages: [ChatMessage]
    var lastMessageId: Int
    var logIndex: [Int32]
    let kNumRecentMessages = 50
    
    var logFileHandle: FileHandle
    var logIndexFileHandle: FileHandle
    
    init?(sessionManager: SessionManager, usersManager:UsersManager) throws {
        self.sessionManager = sessionManager
        self.usersManager = usersManager
        self.recentMessages = []
        self.lastMessageId = 0
        self.logIndex = []
        
        #if os(Linux)
            let url = URL(fileURLWithPath: "/var/lib")
        #elseif os(macOS)
            let url = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        #endif
        let logFileUrl = url.appendingPathComponent("LifeServer/ChatLog.db")
        let logIndexFileUrl = url.appendingPathComponent("LifeServer/ChatLogIndex.db")
        
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
        
        self.sessionManager?.delegate.add(delegate: self)
        
        // Load recent messages and messages index
        var logIndexFileData = logIndexFileHandle.readDataToEndOfFile()
        self.logIndex = logIndexFileData.withUnsafeBytes { (pointer: UnsafePointer<Int32>) -> [Int32] in
            let buffer = UnsafeBufferPointer(start: pointer, count: logIndexFileData.count/4)
            return Array<Int32>(buffer)
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
    
    public func gotMessage(forConnection connectionId:Int32, user userId:Int, msg:[String:Any]) {
        if let messageText = msg["sendMessage"] as? String {
            processChatMessage(withConnection:connectionId, user:userId, messageText:messageText)
        }
        else if let _ = msg["recentMessagesRequest"] as? String {
            processChatRecentMessagesRequest(withConnection:connectionId, user:userId)
        }
        else if let chatHistoryRequest = msg["messagesRequest"] as? [String:Any] {
            processChatMessagesRequest(withConnection:connectionId, user:userId, request:chatHistoryRequest)
        }
    }
    
    public func userLoggedIn(_ userId:Int) {
        
    }
    
    public func userLoggedOut(_ userId:Int) {
        
    }
    
    func processChatMessage(withConnection connectionId:Int32, user userId:Int, messageText:String) {
        do {
            guard let user = usersManager?.getUser(withId: userId) else {
                throw ChatError.MessageFromAnonymousUser
            }
            let userName = user.name
            
            let messageId = self.lastMessageId
            self.lastMessageId += 1
            
            let chatMessage = ChatMessage(messageId:messageId, userName:userName, message:messageText)
            
            self.recentMessages.append(chatMessage)
            if self.recentMessages.count > kNumRecentMessages {
                self.recentMessages.remove(at: 0)
            }
            
            let broadcastChatMessage = BroadcastChatMessage(chatMessage: chatMessage)
            sessionManager?.sendMessageBroadcast(broadcastChatMessage)
            
            seiralQueue.async { [unowned self, chatMessage] in
                do {
                    try self.storeMessage(chatMessage: chatMessage)
                }
                catch {
                    print("Failed to store message: \(error)")
                }
            }
        }
        catch {
            print("Chat: Failed to process incoming message: \(error)")
            
            // Notify client about error
            sessionManager?.sendMessage(connectionId,
                                        codableObj: ChatErrorResponse(status: false, message: "Failed to process incoming message: \(error)"))
        }
    }
    
    func processChatRecentMessagesRequest(withConnection connectionId:Int32, user userId:Int) {
        let recentChatMessages = RecentChatMessages(status: true, recentMessages: self.recentMessages)
        sessionManager?.sendMessage(connectionId, codableObj:recentChatMessages)
    }
    
    func processChatMessagesRequest(withConnection connectionId:Int32, user userId:Int, request:[String:Any]) {
        do {
            guard
                let fromId = request["fromId"] as? Int,
                let count = request["count"] as? Int
                else {
                    throw ChatError.InvalidChatMessagesRequest
            }
                
            var chatMessages = [ChatMessage]()
            
            seiralQueue.sync { [unowned self] in
                do {
                    chatMessages = try self.getMessages(fromId: fromId, count: count)
                }
                catch {
                    print("Failed to get messages: \(error)")
                }
            }
            
            sessionManager?.sendMessage(connectionId,
                                        codableObj: RecentChatMessages(status: true, recentMessages: chatMessages))
        }
        catch {
            print("Chat: Failed to process messages request: \(error)")
            
            // Notify client about error
            sessionManager?.sendMessage(connectionId,
                                        codableObj: ChatErrorResponse(status: false, message: "Failed to process incoming message: \(error)"))
        }
    }
    
    func storeMessage(chatMessage:ChatMessage) throws {
        let logFileSize = self.logFileHandle.offsetInFile
        var index = Int32(logFileSize)
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
            fromId + count < self.lastMessageId
        else {
            throw ChatError.InvalidChatMessagesRequest
        }
        
        let toId = fromId + count
        let fromPos = self.logIndex[fromId]
        var logData: Data
        
        if (toId == self.lastMessageId-1) {
            self.logFileHandle.seek(toFileOffset: UInt64(fromPos))
            logData = self.logFileHandle.readDataToEndOfFile()
        }
        else {
            let toPos = self.logIndex[toId+1]
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
