// -----------------------------------------------------------------------------
//    Copyright (C) 2018 Yauheni Lychkouski.
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
import Dispatch
import NIO
import NIOFoundationCompat

extension Channel {
    var channelId: Int {
        return ObjectIdentifier(self).hashValue
    }
}

final class JsonDes: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias ChannelEventHandler = (Int, ChannelEvent, [String:Any]?) -> Void
    
    enum ChannelEvent {
        case channelOpened
        case channelClosed
        case channelRead
    }
    
    public let channelId: Int
    private let channelEventHandler: ChannelEventHandler
    
    init(channelId: Int, channelEventHandler: @escaping ChannelEventHandler) {
        self.channelId = channelId
        self.channelEventHandler = channelEventHandler
    }
    
    public func channelActive(ctx: ChannelHandlerContext) {
        self.channelEventHandler(self.channelId, .channelOpened, nil)
    }
    
    public func channelInactive(ctx: ChannelHandlerContext) {
        self.channelEventHandler(self.channelId, .channelClosed, nil)
    }
    
    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let byteBuf = self.unwrapInboundIn(data)
        let readData = byteBuf.getData(at:byteBuf.readerIndex, length:byteBuf.readableBytes)!
        
        guard let jsonObject = try? JSONSerialization.jsonObject(with: readData, options: []) else { return }
        guard let message = jsonObject as? [String:Any] else { return }
        
        print(message)
        self.channelEventHandler(self.channelId, .channelRead, message)
    }
    
    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("error: ", error)
        ctx.close(promise: nil)
    }
}

final class JsonSer: ChannelOutboundHandler {
    public typealias OutboundIn = [String:Any]
    public typealias OutboundOut = ByteBuffer
    
    public func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let message = self.unwrapOutboundIn(data)
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted) else { return }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        var buffer = ctx.channel.allocator.buffer(capacity: jsonString.count)
        buffer.write(string: jsonString)
        //ctx.channel.writeAndFlush(buffer, promise: nil)
        ctx.writeAndFlush(self.wrapOutboundOut(buffer), promise: promise)
    }
    
    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("error: ", error)
        ctx.close(promise: nil)
    }
}

class Server {
    public let connectionEstablishedEvent = Event<Int>()
    public let connectionClosedEvent = Event<Int>()
    public let connectionReceivedMessageEvent = Event2<Int, [String:Any]>()
    
    let port: Int
    var group: MultiThreadedEventLoopGroup?
    var listenChannel: Channel?
    let channelsSyncQueue = DispatchQueue(label: "channelsQueue")
    var channels = [Int:Channel]()
    
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
        
        self.listenChannel = try bootstrap.bind(host: "localhost", port: port).wait()
        
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
