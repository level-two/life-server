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

extension LifeServer {
    public func assembleInteractions() {
        let serverInteractor = server.assembleInteractions(disposeBag: disposeBag)
        let sessionManagerInteractor = sessionManager.assembleInteractions(disposeBag: disposeBag)
        let usersManagerInteractor = usersManager.assembleInteractions(disposeBag: disposeBag)
        let gameplayInteractor = gameplay.assembleInteractions(disposeBag: disposeBag)
        let chatInteractor = chat.assembleInteractions(disposeBag: disposeBag)
        
        serverInteractor.onMessage.bind { connectionId, data in
            if let sessionManagerMessage = try? JSONDecoder().decode(SessionManagerMessage.self, from: data) {
                sessionManagerInteractor.onMessage.onNext((connectionId, sessionManagerMessage))
                return
            }
            
            if let usersManagerMessage = try? JSONDecoder().decode(UsersManagerMessage.self, from: data) {
                usersManagerInteractor.onMessage.onNext((connectionId, usersManagerMessage))
                return
            }
            
            guard let userId = sessionManagerInteractor.userId(for: connectionId) else { return } // TODO: userId(for:) can be defined as closure
            
            if let gameplayMessage = try? JSONDecoder().decode(GameplayMessage.self, from: data) {
                gameplayChannelHandler.onMessage.onNext((userId, gameplayMessage))
                return
            }
            
            if let chatMessage = try? JSONDecoder().decode(ChatMessage.self, from: data) {
                chatChannelHandler.onMessage.onNext((userId, chatMessage))
                return
            }
        }.disposed(by: disposeBag)
        
        sessionManagerInteractor.sendMessage.bind { connectionId, message in
            guard let data = try? JSONEncoder().encode(message) else { return }
            serverInteractor.sendMessage.onNext((connectionId, data))
        }.disposed(by: disposeBag)
        
        usersManagerInteractor.sendMessage.bind { connectionId, message in
            guard let data = try? JSONEncoder().encode(message) else { return }
            serverInteractor.sendMessage.onNext((connectionId, data))
        }.disposed(by: disposeBag)
        
        gameplayInteractor.sendMessage.bind { userId, message in
            guard let connectionId = sessionManagerInteractor.connectionId(for: userId) else { return }
            guard let data = try? JSONEncoder().encode(message) else { return }
            serverInteractor.sendMessage.onNext((connectionId, data))
        }.disposed(by: disposeBag)
        
        chatInteractor.sendMessage.bind { userId, message in
            guard let connectionId = sessionManagerInteractor.connectionId(for: userId) else { return }
            guard let data = try? JSONEncoder().encode(message) else { return }
            serverInteractor.sendMessage.onNext((connectionId, data))
        }.disposed(by: disposeBag)
        
        chatInteractor.userLoginStatusRequest
            .bind(to:usersManagerInteractor.userLoginStatusProvider.onNext)
            .disposed(by: disposeBag)
        
        chatInteractor.userDataRequest
            .bind(to: usersManagerInteractor.userDataProvider.onNext)
            .disposed(by: disposeBag)
    }
}
