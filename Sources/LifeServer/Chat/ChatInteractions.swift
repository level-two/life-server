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

extension Chat {
    public class Interactor {
        let onMessage = PublishSubject<(UserId, ChatMessage)>()
        let sendMessage = PublishSubject<(UserId, ChatMessage)>()
        
        var getLoginStatus: (UserId) -> Bool = { _ in false }
        var getUserData: (UserId) -> UserData? = { _ in nil }
    }
    
    public func assembleInteractions(disposeBag: DisposeBag) -> Chat.Interactor {
        // internal interactions
        
        
        // external interactions
        let i = Interactor()
        
        self.sendMessage
            .bind(onNext: i.sendMessage.onNext)
            .disposed(by: disposeBag)
        
        i.onMessage
            .bind(onNext: self.onMessage)
            .disposed(by: disposeBag)
        
        // use getUserData and getLoginStatus here
        
        return i
    }
}
