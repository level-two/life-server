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

protocol ServerProtocol {
    var onConnectionEstablished: Observable<Int> { get }
    var onConnectionClosed     : Observable<Int> { get }
    var onMessage              : Observable<(connectionId: Int, message: Message)> { get }
    var onConnectedToServer    : Observable<Bool> { get }
    
    @discardableResult func send(message: Message) -> Future<Void>
    @discardableResult func sendBroadcast(message: Message) -> Future<Void>
}

class Server: ServerProtocol {
    let onConnectionEstablished = Observable<Int>()
    let onConnectionClosed      = Observable<Int>()
    let onMessage               = Observable<(connectionId: Int, message: Message)>()
    let onConnectedToServer     = Observable<Bool>()
    
    let port: Int
    let host = "192.168.100.64"
    
    
    var listenChannel: Channel?
    var channels = [Int:Channel]()
    
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    var bootstrap: ServerBootstrap {
        return ServerBootstrap(group: self.group)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer { [weak self] channel in
                DispatchQueue.main.async {
                    self?.channels[channel.channelId] = channel
                }
                
                channel.closeFuture.map { _ in
                    DispatchQueue.main.async {
                        self?.channels.removeValue(forKey: channel.channelId)
                    }
                }
                
                return channel.pipeline.addHandlers([
                    FrameChannelHandler(),
                    MessageChannelHandler(),
                    BridgeChannelHandler { [weak self] message in self?.onMessage.notifyObservers(message) }
                    ], first: true)
            }
            // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    }
    
    
    init(port: Int) {
        self.port = port
    }
    
    func runServer() throws {
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        
        let channelEventHandler: JsonDes.ChannelEventHandler = { [weak self] channelId, channelEventType, message in
            switch channelEventType {
            case .channelOpened:
                self?.connectionEstablishedEvent.raise(with: channelId)
            case .channelClosed:
                self?.connectionClosedEvent.raise(with: channelId)
            case .channelRead:
                guard let message = message else { return }
                self?.connectionReceivedMessageEvent.raise(with: channelId, message)
            }
        }
        
        let bootstrap = ServerBootstrap(group: group!)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            
            // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer { [weak self] channel in
                _ = channel.closeFuture.map { _ in
                    self?.channelsSyncQueue.async {
                        self?.channels.removeValue(forKey: channel.channelId)
                    }
                }
                
                self?.channelsSyncQueue.async {
                    self?.channels[channel.channelId] = channel
                }
                
                return channel.pipeline.add(handler:JsonSer()).then {
                    channel.pipeline.add(handler:
                        JsonDes(channelId:channel.channelId, channelEventHandler:channelEventHandler))
                }
            }
            
            // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        
        self.listenChannel = try bootstrap.bind(host: host, port: port).wait()
        
        guard let localAddress = listenChannel?.localAddress else {
            fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
        }
        print("Server started and listening on \(localAddress)")
    }
    
    deinit {
        // Close all open sockets...
        //try! self.listenChannel?.close().wait()
        try! self.group?.syncShutdownGracefully()
    }
}

extension Server {
    public func send(to channelId:Int, message: [String:Any]) {
        var channel: Channel?
        self.channelsSyncQueue.sync {
            channel = self.channels[channelId]
        }
        sleep(4)
        channel?.write(message, promise:nil)
    }
    
    public func sendBroadcast(message: [String:Any]) {
        var channels: Dictionary<Int, Channel>.Values?
        self.channelsSyncQueue.sync {
            channels = self.channels.values
        }
        channels?.forEach { $0.write(message, promise:nil) }
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
