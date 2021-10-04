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
}
