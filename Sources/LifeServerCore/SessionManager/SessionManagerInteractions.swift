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

public protocol LoginStatusProvider: class {
    func userId(for connectionId: ConnectionId) -> UserId?
    func connectionId(for userId: UserId) -> ConnectionId?
    func loginStatus(for userId: UserId) -> Bool
}

extension SessionManager {
    public class Interactor {
        let onMessage = PublishSubject<(ConnectionId, SessionManagerMessage)>()
        let sendMessage = PublishSubject<(ConnectionId, SessionManagerMessage)>()

        fileprivate(set) weak var loginStatusProvider: LoginStatusProvider?
    }

    public func assembleInteractions(disposeBag: DisposeBag) -> SessionManager.Interactor {
        let interactor = Interactor()
        /*
        interactor.onMessage.bind { connectionId, message in
            guard case .login(let userName) = message else { return }
            
            guard interactor.isUserExists(with: userName) else {
                interactor.sendMessage.onNext((connectionId,
                                               .loginUserResponse(userData: nil, error: SessionManagerError.userDoesntExist)))
            }
            
            do {
                try self.login(with: userName)
                
                interactor.sendMessage.onNext((connectionId, .loginUserResponse(userData: userData, error: nil)))
            } catch {
                interactor.sendMessage.onNext((connectionId,
                                               .loginUserResponse(userData: nil, error: error.localizedDescription)))
            }
        }.disposed(by: disposeBag)
        
        interactor.onMessage.bind { connectionId, message in
            guard case .logout(let userName) = message else { return }
            do {
                let userId = try self.logout(with: userName)
                interactor.sendMessage.onNext((connectionId, .logoutUserResponse(userData: userData, error: nil)))
            } catch {
                interactor.sendMessage.onNext((connectionId,
                                               .logoutUserResponse(userData: nil, error: error.localizedDescription)))
            }
            }.disposed(by: disposeBag)
         */
        interactor.loginStatusProvider = self

        return interactor
    }
}
