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

        serverInteractor.onConnectionEstablished.bind(to: onConnectionEstablished).disposed(by: disposeBag)
        serverInteractor.onConnectionClosed.bind(to: onConnectionClosed).disposed(by: disposeBag)
        serverInteractor.onMessage.bind(to: onMessage).disposed(by: disposeBag)

        return serverInteractor
    }

    public func runServer(host: String, port: Int) throws {
        let bootstrap = makeBootstrap { [weak self] channel in
            guard let self = self else { return channel.eventLoop.newFailedFuture(error: ServerError.serverDestroyed) }

            let connectionId = channel.connectionId
            self.storeConnection(channel, with: connectionId)
            self.onConnectionEstablished.onNext(connectionId)

            _ = channel.closeFuture.map { _ in
                self.onConnectionClosed.onNext(connectionId)
                self.removeConnection(with: connectionId)
            }

            let bridge = BridgeChannelHandler()
            bridge.onMessage
                .map { (connectionId, $0) }
                .bind(to: self.onMessage)
                .disposed(by: bridge.disposeBag)

            return channel.pipeline.addHandlers(FrameChannelHandler(), bridge, first: true)
        }

        listenChannel = try bootstrap.bind(host: host, port: port).wait()
        guard let localAddress = listenChannel?.localAddress else {
            print("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
            throw ServerError.addressBindError
        }

        print("Server started and listening on \(localAddress)")
    }
}
