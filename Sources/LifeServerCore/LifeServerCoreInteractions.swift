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

extension LifeServerCore {
    open class Interactor {
    }

    open func assembleInteractions() {
        let serverInteractor = server.assembleInteractions(disposeBag: disposeBag)
        let sessionManagerInteractor = sessionManager.assembleInteractions(disposeBag: disposeBag)
        let usersManagerInteractor = usersManager.assembleInteractions(disposeBag: disposeBag)
        let gameplayInteractor = gameplay.assembleInteractions(disposeBag: disposeBag)
        let chatInteractor = chat.assembleInteractions(disposeBag: disposeBag)

        serverInteractor.onMessage.bind { connectionId, data in
            // TODO: Think about json or incoming message validation before using it
            print("🔥 Got data: \(String(data: data, encoding: .utf8)!)")
            
            if let sessionManagerMessage = try? JSONDecoder().decode(SessionManagerMessage.self, from: data) {
                sessionManagerInteractor.onMessage.onNext((connectionId, sessionManagerMessage))
                return
            }

            if let usersManagerMessage = try? JSONDecoder().decode(UsersManagerMessage.self, from: data) {
                usersManagerInteractor.onMessage.onNext((connectionId, usersManagerMessage))
                return
            }

            if let gameplayMessage = try? JSONDecoder().decode(GameplayMessage.self, from: data) {
                gameplayInteractor.onMessage.onNext((connectionId, gameplayMessage))
                return
            }

            if let chatMessage = try? JSONDecoder().decode(ChatMessage.self, from: data) {
                chatInteractor.onMessage.onNext((connectionId, chatMessage))
                return
            }
        }.disposed(by: disposeBag)

        serverInteractor.onConnectionEstablished
            .bind(to: sessionManagerInteractor.onConnectionEstablished)
            .disposed(by: disposeBag)

        serverInteractor.onConnectionClosed
            .bind(to: sessionManagerInteractor.onConnectionClosed)
            .disposed(by: disposeBag)

        sessionManagerInteractor.sendMessage
            .map { ($0, try JSONEncoder().encode($1)) }
            .bind(onNext: server.send)
            .disposed(by: disposeBag)

        usersManagerInteractor.sendMessage
            .map { ($0, try JSONEncoder().encode($1)) }
            .bind(onNext: server.send)
            .disposed(by: disposeBag)

        gameplayInteractor.broadcastMessage
            .map { try JSONEncoder().encode($0) }
            .bind { [weak self] data in
                self?.sessionManager.connectionsForLoggedUsers?.forEach { self?.server.send(for: $0, data) }
            }.disposed(by: disposeBag)

        chatInteractor.sendMessage
            .map { ($0, try JSONEncoder().encode($1)) }
            .bind(onNext: server.send)
            .disposed(by: disposeBag)
        
        chatInteractor.broadcastMessage
            .map { try JSONEncoder().encode($0) }
            .bind { [weak self] data in
                self?.sessionManager.connectionsForLoggedUsers?.forEach { self?.server.send(for: $0, data) }
            }.disposed(by: disposeBag)
    }

    public func runServer(host: String, port: Int) throws {
        try server.runServer(host: host, port: port)
    }
}
