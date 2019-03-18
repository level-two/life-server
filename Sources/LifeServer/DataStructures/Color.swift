//
//  Color.swift
//  LifeClient
//
//  Created by Yauheni Lychkouski on 2/4/19.
//  Copyright © 2019 Yauheni Lychkouski. All rights reserved.
//

import Foundation
import UIKit

struct Color: Codable {
    let r, g, b, a: CGFloat
}

extension Color {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        r = try container.decode(CGFloat.self)/255
        g = try container.decode(CGFloat.self)/255
        b = try container.decode(CGFloat.self)/255
        a = try container.decode(CGFloat.self)/255
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(Int(r*255))
        try container.encode(Int(g*255))
        try container.encode(Int(b*255))
        try container.encode(Int(a*255))
    }
}

extension Color {
    var uiColor: UIColor { return UIColor(color: self) }
    var cgColor: CGColor { return uiColor.cgColor }
    var ciColor: CIColor { return CIColor(color: uiColor) }
    var data: Data { return try! JSONEncoder().encode(self) }
}

extension UIColor {
    convenience init(color: Color) {
        self.init(red: color.r, green: color.g, blue: color.b, alpha: color.a)
    }
    var color: Color {
        let color = CIColor(color: self)
        return Color(r: color.red, g: color.green, b: color.blue, a: color.alpha)
    }
}
