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
import NIO
import RxSwift
import RxCocoa

extension Server {
    public class ServerInteractor {
        let onConnectionEstablished = PublishSubject<ConnectionId>()
        let onConnectionClosed      = PublishSubject<ConnectionId>()
        let onMessage               = PublishSubject<(ConnectionId, Data)>()
        
        let sendMessage             = PublishSubject<(ConnectionId, Data)>()
    }
    
    public func assembleInteractions(disposeBag: DisposeBag) -> ServerInteractor {
        let i = ServerInteractor()
        
        i.sendMessage
            .observeOn(MainScheduler.instance)
            .bind { [weak self] connectionId, data in self?.send(data, for: connectionId) }
            .disposed(by: disposeBag)
        
        onConnectionEstablished
            .bind(onNext: i.onConnectionEstablished.onNext)
            .disposed(by: disposeBag)
        
        onConnectionClosed
            .bind(onNext: i.onConnectionClosed.onNext)
            .disposed(by: disposeBag)
        
        onMessage
            .bind(onNext: i.onMessage.onNext)
            .disposed(by: disposeBag)
        
        return i
    }
}
