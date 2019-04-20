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

public enum ChatError: Error {
    case notLoggedIn
    case logFileInvalidHandler
    case invalidChatMessagesRequest
    case invalidChatMessage
}

class Chat {
    init(userInfoProvider: UserInfoProvider, sessionInfoProvider: SessionInfoProvider, chatDatabase: ChatDatabase) {
        self.userInfoProvider = userInfoProvider
        self.sessionInfoProvider = sessionInfoProvider
        self.chatDatabase = chatDatabase
    }

    let userInfoProvider: UserInfoProvider
    let sessionInfoProvider: SessionInfoProvider
    let chatDatabase: ChatDatabase

    /*
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
 */
}
