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

extension UsersManager {
    public class Interactor {
        let onMessage = PublishSubject<(ConnectionId, UsersManagerMessage)>()
        var sendMessage = PublishSubject<(ConnectionId, UsersManagerMessage)>()
    }

    public func assembleInteractions(disposeBag: DisposeBag) -> UsersManager.Interactor {
        let interactor = Interactor()

        interactor.onMessage.bind { [weak self] connectionId, message in
            guard let self = self else { return }
            guard case .createUser(let userName, let color) = message else { return }

            firstly {
                self.database.numberOfRegisteredUsers()
            }.then {
                self.database.store(userData: .init(userId: $0 + 1, userName: userName, color: color))
            }.map {
                interactor.sendMessage.onNext((connectionId, .createUserSuccess(userData: $0)))
            }.catch {
                interactor.sendMessage.onNext((connectionId, .createUserError(error: $0.localizedDescription)))
            }
        }.disposed(by: disposeBag)

        return interactor
    }
}
