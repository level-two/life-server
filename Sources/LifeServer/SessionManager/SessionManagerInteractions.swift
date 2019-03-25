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
        // internal interactions
        
        // external interactions
        let i = Interactor()
        
        i.onMessage.bind { message in
            print(message)
        }.disposed(by: disposeBag)
        
        i.loginStatusProvider = self
        
        return i
    }
}
