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

extension DatabaseManager {
    public class Interactor {
        let containsUserWithId = RequestSubject<UserId, Bool>()
        let containsUserWithName = RequestSubject<String, Bool>()
        let store = RequestSubject<UserData, UserData>()
        let userDataWithId = RequestSubject<UserId, UserData>()
        let userDataWithName = RequestSubject<String, UserData>()
        let numberOfRegisteredUsers = RequestSubject<String, Int>()
    }
    
    public func assembleInteractions(disposeBag: DisposeBag) -> Interactor {
        let interactor = Interactor()
        
        numberOfRegisteredUsers.requestSubject.bind { [weak self] _, responseObservable in
            self?.numberOfRegisteredUsers().bind(to:responseObservable).disposed(by: disposeBag)
        }
    
        return interactor
    }
}
