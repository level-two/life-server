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

protocol UserDatabase: class {
    func containsUser(with userId: UserId) -> Future<Bool>
    func containsUser(with userName: String) -> Future<Bool>
    func store(userData: UserData) -> Future<Void>
    func userData(with userId: UserId) -> Future<UserData>
    func userData(with userName: String) -> Future<UserData>
}

protocol ChatDatabase: class {
}

extension DatabaseManager {
    public class Interactor {
        fileprivate(set) weak var userDatabase: UserDatabase?
        fileprivate(set) weak var chatDatabase: ChatDatabase?
    }
    
    public func assembleInteractions(disposeBag: DisposeBag) -> Interactor {
        let interactor = Interactor()
        
        interactor.userDatabase = self
        interactor.chatDatabase = self
        
        return interactor
    }
}
