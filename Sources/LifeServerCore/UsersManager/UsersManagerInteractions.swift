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
            
            self.database.numberOfRegisteredUsers()
                .chained { lastUserId -> Future<UserData> in
                    let userData = UserData(userId: lastUserId+1, userName: userName, color: color)
                    return self.database.store(userData: userData)
                }.observe { result in
                    switch result {
                    case .error(let error):
                        interactor.sendMessage.onNext((connectionId, .createUserError(error: error.localizedDescription)))
                    case .value(let userData):
                        interactor.sendMessage.onNext((connectionId, .createUserSuccess(userData: userData)))
                    }
                }
        }.disposed(by: disposeBag)
        
        return interactor
    }
}
