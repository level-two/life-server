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
        var sendMessage:                     (ConnectionId, UsersManagerMessage) -> Void = { _,_ in fatalError() }
        var databaseContainsUserWithId:      (UserId) -> Promise<Bool>                   = { _ in fatalError() }
        var databaseContainsUserWithName:    (String) -> Promise<Bool>                   = { _ in fatalError() }
        var databaseStore:                   (UserData) -> Promise<UserData>             = { _ in fatalError() }
        var databaseUserDataWithId:          (UserId) -> Promise<UserData>               = { _ in fatalError() }
        var databaseUserDataWithName:        (String) -> Promise<UserData>               = { _ in fatalError() }
        var databaseNumberOfRegisteredUsers: (String) -> Promise<Int>                    = { _ in fatalError() }
    }

    public func assembleInteractions(disposeBag: DisposeBag) -> UsersManager.Interactor {
        let interactor = Interactor()

        interactor.onMessage.bind { connectionId, message in
            guard case .createUser(let userName, let color) = message else { return }
            
            interactor.databaseNumberOfRegisteredUsers(userName).chained { lastUserId -> Future<UserData> in
                let userData = UserData(userId: lastUserId+1, userName: userName, color: color)
                return interactor.databaseStore(userData)
            }.observe { result in
                switch result {
                case .error(let error):
                    interactor.sendMessage(connectionId, .createUserError(error: error.localizedDescription))
                case .value(let userData):
                    interactor.sendMessage(connectionId, .createUserSuccess(userData: userData))
                }
            }
        }.disposed(by: disposeBag)
        
        /*
        interactor.userData = { [weak self] userId in
            guard let self = self else { return .empty() }
            return interactor.dbUserDataWithId(userId)
        }
        //}.disposed(by: disposeBag) // <---- here it is desired implementation of binding closure to the "requestable subject"
         */
        // Interactor should have same life time as Users Manager
        // But irl it can be different - longer or shorter, and both these situations should be handled
        // 1. if interactor have shorter life time, it will be destroyed using disposeBag
        // 2. if UsersManager destroyed before interactor, [weak self] and then check if self is not nil should do the trick
        return interactor
    }
}
