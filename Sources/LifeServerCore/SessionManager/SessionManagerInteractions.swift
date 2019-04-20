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

enum SessionManagerError: Int, Error {
    case invalidUserCreateRequest
    case invalidUserLoginRequest
    case invalidUserLogoutRequest
    case userDoesntExist
    case createUserReturnedNil
    case userIsNotLoggedIn
    case userAlreadyLoggedIn
    case anotherUserAlreadyLoggedIn
    case userAlreadyLoggedOut
    case invalidUserIdForLogout
    case noSessionForConnection
}

extension SessionManager {
    public class Interactor {
        let onMessage = PublishSubject<(ConnectionId, SessionManagerMessage)>()
        let sendMessage = PublishSubject<(ConnectionId, SessionManagerMessage)>()

        let onConnectionEstablished = PublishSubject<ConnectionId>()
        let onConnectionClosed      = PublishSubject<ConnectionId>()
    }

    public func assembleInteractions(disposeBag: DisposeBag) -> SessionManager.Interactor {
        let interactor = Interactor()

        interactor.onMessage.bind { [weak self] connectionId, message in
            guard let self = self else { return }
            guard case .login(let userName) = message else { return }

            firstly {
                self.database.userData(with: userName)
            }.map { userData in
                guard !self.isLoggedIn(userData.userId) else { throw SessionManagerError.userAlreadyLoggedIn }
                guard !self.isLoggedIn(on: connectionId) else { throw SessionManagerError.anotherUserAlreadyLoggedIn }
                self.login(userData.userId, on: connectionId)
                interactor.sendMessage.onNext((connectionId, .loginResponseSuccess(userData: userData)))
            }.catch {
                interactor.sendMessage.onNext((connectionId, .loginResponseError(error: $0.localizedDescription)))
            }

        }.disposed(by: disposeBag)

        interactor.onMessage.bind { [weak self] connectionId, message in
            guard let self = self else { return }
            guard case .logout(let userName) = message else { return }

            firstly {
                self.database.userData(with: userName)
            }.map { userData in
                guard self.isLoggedIn(userData.userId) else { throw SessionManagerError.userIsNotLoggedIn }
                guard self.isLoggedIn(on: connectionId) else { throw SessionManagerError.noSessionForConnection }
                guard self.userId(for: connectionId) == userData.userId else { throw SessionManagerError.invalidUserIdForLogout }
                self.logout(userData.userId, on: connectionId)
                interactor.sendMessage.onNext((connectionId, .logoutResponseSuccess(userData: userData)))
            }.catch {
                interactor.sendMessage.onNext((connectionId, .logoutResponseError(error: $0.localizedDescription)))
            }
        }.disposed(by: disposeBag)

        interactor.onConnectionEstablished
            .bind { [weak self] connectionId in self?.connectionEstablished(with: connectionId) }
            .disposed(by: disposeBag)

        interactor.onConnectionClosed
            .bind { [weak self] connectionId in self?.connectionClosed(with: connectionId) }
            .disposed(by: disposeBag)

        return interactor
    }
}
