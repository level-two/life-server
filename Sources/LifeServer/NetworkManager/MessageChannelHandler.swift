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
import NIO

final class MessageChannelHandler: ChannelInboundHandler, ChannelOutboundHandler {
    public typealias InboundIn = Data
    public typealias InboundOut = Message
    public typealias OutboundIn = Message
    public typealias OutboundOut = Data
    
    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        do {
            let jsonData = self.unwrapInboundIn(data)
            let message = try JSONDecoder().decode(Message.self, from: jsonData)
            ctx.fireChannelRead(self.wrapInboundOut(message))
        }
        catch {
            ctx.fireErrorCaught(error)
        }
    }
    
    func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        do {
            let message = self.unwrapOutboundIn(data)
            let data = try JSONEncoder().encode(message)
            ctx.write(self.wrapOutboundOut(data)).cascade(promise: promise)
        }
        catch {
            promise?.fail(error: error)
        }
    }
    
    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("MessageHandler cought error: ", error)
        ctx.close(promise: nil)
    }
}


