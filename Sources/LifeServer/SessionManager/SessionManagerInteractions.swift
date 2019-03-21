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

extension SessionManager {
    public class Interactor {
        let onMessage = PublishSubject<(Server.ConnectionId, SessionManagerMessage)>()
        let sendMessage = PublishSubject<(Server.ConnectionId, SessionManagerMessage)>()
        
        fileprivate(set) var getUserId: (Server.ConnectionId) -> UserId? = { _ in nil }
        fileprivate(set) var getConnectionId: (UserId) -> Server.ConnectionId? = { _ in nil }
        fileprivate(set) var getLoginStatus: (UserId) -> Bool = { _ in false }
    }
    
    public func assembleInteractions(disposeBag: DisposeBag) -> SessionManager.Interactor {
        // internal interactions
        
        
        // external interactions
        let i = Interactor()
        
        i.onMessage
            .bind(onNext: self.onMessage)
            .disposed(by: disposeBag)
        
        self.sendMessage
            .bind(onNext: i.sendMessage.onNext)
            .disposed(by: disposeBag)
        
        i.getUserId = { [weak self] connectionId in return self?.getUserId(for: connectionId) }
        i.getConnectionId = { [weak self] userId in return self?.getConnectionId(for: userId) }
        i.getLoginStatus = { [weak self] userId in
            guard let self = self else { return false }
            return self.getLoginStatus(for: userId)
        }
        
        return i
    }
}
