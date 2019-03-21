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

class Server {
    public typealias ConnectionId = Int

    public func run(host: String, port: Int) throws {
        self.host = host
        self.port = port
        self.listenChannel = try bootstrap.bind(host: host, port: port).wait()
        guard let localAddress = listenChannel?.localAddress else {
            fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
        }
        print("Server started and listening on \(localAddress)")
    }
    
    deinit {
        // Close all opened sockets...
        //try! self.listenChannel?.close().wait()
        try! self.group.syncShutdownGracefully()
    }
    
    var port = 0
    var host = ""
    var listenChannel: Channel?
    var connections = [ConnectionId:Channel]()
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    
    let onConnectionEstablished = PublishSubject<ConnectionId>()
    let onConnectionClosed      = PublishSubject<ConnectionId>()
    let onMessage               = PublishSubject<(ConnectionId, Data)>()
    
    var bootstrap: ServerBootstrap {
        return ServerBootstrap(group: self.group)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer(channelInitializer)
            // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    }
}

extension Server {
    func channelInitializer(_ channel: Channel) -> EventLoopFuture<Void> {
        DispatchQueue.main.async { [weak self] in
            self?.connections[channel.connectionId] = channel
            self?.onConnectionEstablished.onNext(channel.connectionId)
        }
        
        _ = channel.closeFuture.map { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.connections.removeValue(forKey: channel.connectionId)
                self?.onConnectionClosed.onNext(channel.connectionId)
            }
        }
        // TODO: Check whether channel and bridge are destroyed - do we need [unowned channel] ?
        let bridge = BridgeChannelHandler()
        bridge.onMessage
            .bind { [weak self, unowned channel] message in self?.onMessage.onNext((channel.connectionId, message)) }
            .disposed(by: bridge.disposeBag)
        
        return channel.pipeline.addHandlers(FrameChannelHandler(), bridge, first: true)
    }
    
    func send(_ data: Data, for connectionId: ConnectionId) {
        _ = connections[connectionId]?.writeAndFlush(NIOAny(data))
    }
}

extension Channel {
    var connectionId: Server.ConnectionId {
        return ObjectIdentifier(self).hashValue
    }
}
