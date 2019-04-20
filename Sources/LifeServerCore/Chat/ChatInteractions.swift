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
import PromiseKit

extension Chat {
    public class Interactor {
        let onMessage = PublishSubject<(ConnectionId, ChatMessage)>()
        let sendMessage = PublishSubject<(ConnectionId, ChatMessage)>()
        let broadcastMessage = PublishSubject<ChatMessage>()
    }

    public func assembleInteractions(disposeBag: DisposeBag) -> Chat.Interactor {
        let interactor = Interactor()

        interactor.onMessage.bind { [weak self] connectionId, message in
            guard let self = self else { return }
            guard case .sendChatMessage(let text) = message else { return }

            firstly {
                self.chatDatabase.numberOfStoredMessages()
            }.map { numberOfMessages throws in
                guard let userId = self.sessionInfoProvider.userId(for: connectionId) else { throw ChatError.notLoggedIn }
                return (numberOfMessages, userId)
            }.then { numberOfMessages, userId in
                self.chatDatabase.store(chatMessageData: .init(messageId: numberOfMessages, userId: userId, text: text))
            }.map {
                interactor.broadcastMessage.onNext(.chatMessage(message: $0))
            }.catch {
                interactor.sendMessage.onNext((connectionId, .chatError(error: $0.localizedDescription)))
            }
        }.disposed(by: disposeBag)

        interactor.onMessage.bind { [weak self] connectionId, message in
            guard let self = self else { return }
            guard case .chatHistoryRequest(let fromId, let count) = message else { return }

            // TBI!
            firstly {
                chatDatabase.getMessages(fromId: fromId, toId: fromId+count-1)
            }.map {
                interactor.broadcastMessage.onNext(.chatHistoryResponse(messages: $0))
            }.catch {
                interactor.sendMessage.onNext((connectionId, .chatHistoryError(error: $0.localizedDescription)))
            }
        }.disposed(by: disposeBag)

        /*
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
        */
        /*
        func processChatRecentMessagesRequest(withConnection connectionId:Int, user userId:Int, request: [String:Any]) {
            var chatMessages: [ChatMessage]?
            if let fromId = request["fromId"] as? Int {
                seiralQueue.sync { [weak self] in
                    guard let strongSelf = self else { return }
                    chatMessages = try? strongSelf.getMessages(fromId: fromId, count: strongSelf.lastMessageId - fromId)
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
        */

        return interactor
    }
}
