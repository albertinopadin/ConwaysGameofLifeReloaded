//
//  CGPointExtension.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 10/2/21.
//  Copyright © 2021 Albertino Padin. All rights reserved.
//

import SpriteKit

extension CGPoint {
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
    
    func rotate(around center: CGPoint, degrees: CGFloat) -> CGPoint {
        let dx = self.x - center.x
        let dy = self.y - center.y
        let radius = sqrt(dx * dx + dy * dy)
        let azimuth = atan2(dy, dx) // in radians
        let newAzimuth = azimuth + degrees * CGFloat(.pi / 180.0) // convert it to radians
        let x = center.x + radius * cos(newAzimuth)
        let y = center.y + radius * sin(newAzimuth)
        return CGPoint(x: x, y: y)
    }
}
