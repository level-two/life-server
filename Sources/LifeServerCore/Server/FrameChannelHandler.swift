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

class FrameChannelHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias InboundOut = Data

    public enum FrameError: Error {
        case unableGetDataChunk
        case messageToDataFailed
    }
    
    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let byteBuf = self.unwrapInboundIn(data)
        guard let chunk = byteBuf.getString(at: byteBuf.readerIndex, length: byteBuf.readableBytes) else {
            ctx.fireErrorCaught(FrameError.unableGetDataChunk)
            return
        }
        collected += chunk

        while let newlineRange = collected.rangeOfCharacter(from: .newlines) {
            let message = collected[..<newlineRange.lowerBound]

            if let messageData = message.data(using: .utf8) {
                ctx.fireChannelRead(self.wrapInboundOut(messageData))
            } else {
                ctx.fireErrorCaught(FrameError.messageToDataFailed)
            }

            collected.removeSubrange(..<newlineRange.upperBound)
        }
    }

    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("CollectingInboundHandler caught error: ", error)
        ctx.close(promise: nil)
    }
    
    fileprivate var collected = ""
}
