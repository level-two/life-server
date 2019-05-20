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
        
        while let jsonRange = jsonRange(in: collected) {
            let message = collected[jsonRange]

            if let messageData = message.data(using: .utf8) {
                ctx.fireChannelRead(self.wrapInboundOut(messageData))
            } else {
                ctx.fireErrorCaught(FrameError.messageToDataFailed)
            }

            collected.removeSubrange(...jsonRange.upperBound)
        }
    }

    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("CollectingInboundHandler caught error: ", error)
        ctx.close(promise: nil)
    }
    
    func jsonRange(in string: String) -> ClosedRange<String.Index>? {
        guard let leftBound = string.firstIndex(of: "{") else { return nil }
        
        var bracesCount = 0
        var rightBound = leftBound
        
        repeat {
            if string[rightBound] == "{" {
                bracesCount += 1
            }
            
            if string[rightBound] == "}" {
                bracesCount -= 1
                if bracesCount == 0 {
                    break
                }
            }
            
            rightBound = string.index(after: rightBound)
        } while rightBound != string.endIndex
        
        guard rightBound != string.endIndex else { return nil }
        
        return leftBound...rightBound
    }
    
    fileprivate var collected = ""
}
