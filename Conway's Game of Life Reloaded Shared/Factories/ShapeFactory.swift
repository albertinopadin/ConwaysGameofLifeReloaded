//
//  ShapeFactory.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 10/2/21.
//  Copyright © 2021 Albertino Padin. All rights reserved.
//

import SpriteKit


public final class ShapeFactory {
    private let cellSize: CGFloat
    
    public init(cellSize: CGFloat) {
        self.cellSize = cellSize
    }
    
    public func createSquare(at point: CGPoint) -> [CGPoint] {
        // Actually, need to get current cell user clicked in to properly place square...
        let topLeft  = CGPoint(x: point.x - self.cellSize/2, y: point.y - self.cellSize/2)
        let topRight = CGPoint(x: point.x + self.cellSize/2, y: point.y - self.cellSize/2)
        let botLeft  = CGPoint(x: point.x - self.cellSize/2, y: point.y + self.cellSize/2)
        let botRight = CGPoint(x: point.x + self.cellSize/2, y: point.y + self.cellSize/2)
        return [topLeft, topRight, botLeft, botRight]
    }
    
    public func createRectangle(at point: CGPoint, width: Int, height: Int) -> [CGPoint] {
        var rect = [CGPoint]()
        let pOffset = CGPoint(x: cellSize*(CGFloat(width)/2), y: cellSize*(CGFloat(height)/2))
        for x in 0..<width {
            for y in 0..<height {
                rect.append(CGPoint(x: point.x + CGFloat(x)*(cellSize/2),
                                    y: point.y + CGFloat(y)*(cellSize/2)) - pOffset)
            }
        }
        return rect
    }
}

