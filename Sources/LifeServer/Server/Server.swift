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
    deinit {
        // Close all opened sockets...
        //try! self.listenChannel?.close().wait()
        try! self.group.syncShutdownGracefully()
    }

    var listenChannel: Channel?
    var connections = [ConnectionId: Channel]()
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    func makeBootstrap(with channelInitializer: @escaping (Channel)->EventLoopFuture<Void>) -> ServerBootstrap {
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

    func storeConnection(_ connection: Channel, with connectionId: ConnectionId) {
        DispatchQueue.main.async { [weak self] in
            self?.connections[connectionId] = connection
        }
    }

    func removeConnection(with connectionId: ConnectionId) {
        DispatchQueue.main.async { [weak self] in
            self?.connections.removeValue(forKey: connectionId)
        }
    }
}

extension Server {
    func send(_ data: Data, for connectionId: ConnectionId) {
        DispatchQueue.main.async { [weak self] in
            self?.connections[connectionId]?.writeAndFlush(NIOAny(data), promise: nil)
        }
    }
}

extension Channel {
    var connectionId: ConnectionId {
        return ObjectIdentifier(self).hashValue
    }
}
