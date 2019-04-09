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

enum UserManagerError: Error {
    case invalidMessage
}

extension UsersManager {
    public class Interactor {
        let onMessage = PublishSubject<(ConnectionId, UsersManagerMessage)>()
        let doSendMessage = PublishSubject<(ConnectionId, UsersManagerMessage)>()

        let onGetUserData = PublishSubject<(UserId, Promise<UserData>)>()
        
        let databaseContainsUserWithId = RequestSubject<UserId, Bool>()
        let databaseContainsUserWithName = RequestSubject<String, Bool>()
        let databaseStore = RequestSubject<UserData, UserData>()
        let databaseUserDataWithId = RequestSubject<UserId, UserData>()
        let databaseUserDataWithName = RequestSubject<String, UserData>()
        let databaseNumberOfRegisteredUsers = RequestSubject<Void, Int>()
    }

    public func assembleInteractions(disposeBag: DisposeBag) -> UsersManager.Interactor {
        let interactor = Interactor()
        
        interactor.onMessage.bind { connectionId, message in
            guard case .createUser(let userName, let color) = message else { return }
            
            interactor
                .databaseNumberOfRegisteredUsers.request(())
                .map { UserData(userId: $0 + 1, userName: userName, color: color) }
                .flatMap { interactor.databaseStore.request($0) }
                .subscribe { ev in
                    if case .next(let userData) = ev {
                        interactor.doSendMessage.onNext((connectionId, .createUserResponse(userData: userData, error: nil)))
                    } else {
                        let err = "Failed to create user with name \(userName): \(ev.error!)"
                        interactor.doSendMessage.onNext((connectionId, .createUserResponse(userData: nil, error: err)))
                    }
                }.disposed(by: disposeBag)
        }.disposed(by: disposeBag)
        
        return interactor
    }
}

