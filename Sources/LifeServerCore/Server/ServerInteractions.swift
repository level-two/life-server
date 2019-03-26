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
        let onConnectionClosed      = PublishSubject<ConnectionId>()
        let onMessage               = PublishSubject<(ConnectionId, Data)>()

        let sendMessage             = PublishSubject<(ConnectionId, Data)>()

        fileprivate(set) var runServer: (_ host: String, _ port: Int) -> Void = { _, _ in }
    }

    public func assembleInteractions(disposeBag: DisposeBag) -> Server.Interactor {
        let serverInteractor = Server.Interactor()

        serverInteractor.sendMessage
            .observeOn(MainScheduler.instance)
            .bind { [weak self] connectionId, data in self?.send(data, for: connectionId) }
            .disposed(by: disposeBag)

        serverInteractor.runServer = { [weak self, weak serverInteractor] host, port in
            guard let self = self else { return }

            let bootstrap = self.makeBootstrap { [weak self, weak serverInteractor] channel in
                let connectionId = channel.connectionId

                self?.storeConnection(channel, with: connectionId)
                serverInteractor?.onConnectionEstablished.onNext(connectionId)

                _ = channel.closeFuture.map { [weak self, weak serverInteractor] _ in
                    self?.removeConnection(with: connectionId)
                    serverInteractor?.onConnectionClosed.onNext(connectionId)
                }

                let bridge = BridgeChannelHandler()
                bridge.onMessage
                    .bind { [weak serverInteractor] message in serverInteractor?.onMessage.onNext((connectionId, message)) }
                    .disposed(by: bridge.disposeBag)

                return channel.pipeline.addHandlers(FrameChannelHandler(), bridge, first: true)
            }

            self.listenChannel = try? bootstrap.bind(host: host, port: port).wait()
            guard let localAddress = self.listenChannel?.localAddress else {
                fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
            }

            print("Server started and listening on \(localAddress)")
        }

        return serverInteractor
    }
}
