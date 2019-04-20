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

            firstly {
                self.chatDatabase.messages(fromId: fromId, toId: fromId+count-1)
            }.map {
                interactor.broadcastMessage.onNext(.chatHistoryResponse(messages: $0))
            }.catch {
                interactor.sendMessage.onNext((connectionId, .chatHistoryError(error: $0.localizedDescription)))
            }
        }.disposed(by: disposeBag)

        return interactor
    }
}
