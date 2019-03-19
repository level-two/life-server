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

typealias ConnectionId = Int

struct ServerInteractor {
    let onConnectionEstablished = PublishSubject<(ConnectionId)>()
    let onConnectionClosed      = PublishSubject<(ConnectionId)>()
    let onMessage               = PublishSubject<(ConnectionId, Data)>()
    
    let sendMessage             = PublishSubject<(ConnectionId, Data, Promise<Void>?)>()
    let sendMessageBroadcast    = PublishSubject<(Data, Promise<Void>?)>()
}

class Server {
    let port = 0
    let host = ""
    
    let onConnectionEstablished = PublishSubject<ConnectionId>()
    let onConnectionClosed      = PublishSubject<ConnectionId>()
    
    var listenChannel: Channel?
    var connections = [ConnectionId:Channel]()
    
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    var bootstrap: ServerBootstrap {
        return ServerBootstrap(group: self.group)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer { [weak self] channel in
                
                
                DispatchQueue.main.async {
                    self?.connections[channel.channelId] = channel
                    self?.onConnectionEstablished.onNext(channel.channelId)
                }
                
                channel.closeFuture.map { [weak self] _ in
                    DispatchQueue.main.async { [weak self] in
                        self?.connections.removeValue(forKey: channel.channelId)
                        self?.onConnectionClosed.onNext(channel.channelId)
                    }
                }
                
                let bridgeChannelHandler = BridgeChannelHandler()
                bridgeChannelHandler.onReceived.bind {
                    
                }.disposed(by: bridgeChannelHandler.disposeBag)
                
                return channel.pipeline.addHandlers([
                    FrameChannelHandler(),
                    bridgeChannelHandler
                    ], first: true)
            }
            // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    }
    
    func run(host: String, port: Int) throws {
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
        try! self.group?.syncShutdownGracefully()
    }
}

extension Server {
    public func send(to channelId:Int, message: [String:Any]) {
        var channel: Channel?
        self.channelsSyncQueue.sync {
            channel = self.connections[channelId]
        }
        channel?.write(message, promise:nil)
    }
    
    public func sendBroadcast(message: [String:Any]) {
        var connections: Dictionary<Int, Channel>.Values?
        self.channelsSyncQueue.sync {
            connections = self.connections.values
        }
        connections?.forEach { $0.write(message, promise:nil) }
    }
}




class NetworkManager: NetworkManagerProtocol {
    let onMessage           = Observable<Message>()
    let onConnectedToServer = Observable<Bool>()
    
    let host = "192.168.100.64"
    let port = 1337
    
    
    var channel: Channel? = nil
    var shouldReconnect: Bool = true
    var isConnected = false { didSet { onConnectedToServer.notifyObservers(self.isConnected) } }
    
    func setupDependencies(appState: ApplicationStateObservable) {
        appState.appStateObservable.addObserver(self) { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .didEnterBackground:
                self.shouldReconnect = false
                _ = self.channel?.close()
            case .willEnterForeground:
                self.shouldReconnect = true
                self.run()
            default: ()
            }
        }
    }
    
    @discardableResult
    func send(message: Message) -> Future<Void> {
        guard let writeFuture = channel?.writeAndFlush(NIOAny(message)) else {
            return Promise<Void>(error: "No connection")
        }
        
        let promise = Promise<Void>()
        writeFuture.whenSuccess { promise.resolve(with: ()) }
        writeFuture.whenFailure { error in promise.reject(with: error) }
        return promise
    }
    
    func run() {
        print("Connecting to \(host):\(port)...")
        self.bootstrap
            .connect(host: self.host, port: self.port)
            .then { [weak self] channel -> EventLoopFuture<Void> in
                print("Connected")
                self?.channel = channel
                self?.isConnected = true
                return channel.closeFuture
            }.whenComplete { [weak self] in
                guard let self = self else { return }
                print("Not connected")
                self.channel = nil
                self.isConnected = false
                if self.shouldReconnect {
                    sleep(1)
                    self.run()
                }
            }
    }
}
