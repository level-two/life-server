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
    public class Interactor {
        let onConnectionEstablished = PublishSubject<ConnectionId>()
        let onConnectionClosed = PublishSubject<ConnectionId>()
        let onMessage = PublishSubject<(ConnectionId, Data)>()
    }

    public func assembleInteractions(disposeBag: DisposeBag) -> Server.Interactor {
        let serverInteractor = Server.Interactor()

        onConnectionEstablished.bind(to: serverInteractor.onConnectionEstablished).disposed(by: disposeBag)
        onConnectionClosed.bind(to: serverInteractor.onConnectionClosed).disposed(by: disposeBag)
        onMessage.bind(to: serverInteractor.onMessage).disposed(by: disposeBag)

        return serverInteractor
    }
}
