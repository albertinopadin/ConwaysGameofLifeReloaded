//
//  SpaceshipFactory.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 3/16/21.
//  Copyright © 2021 Albertino Padin. All rights reserved.
//


// TODO: Need to figure out how to get into "Put spaceship here" mode
import SpriteKit

public final class SpaceshipFactory {
    private let cellSize: CGFloat
    
    public init(cellSize: CGFloat) {
        // TODO: Need cell dimensions to properly place the points
        //       relative to one another.
        self.cellSize = cellSize
    }
    
//    public func createGlider(at point: CGPoint) -> [CGPoint] {
//        
//    }
    
    public func createSquare(at point: CGPoint) -> [CGPoint] {
        let topLeft  = CGPoint(x: point.x - self.cellSize, y: point.y - self.cellSize)
        let topRight = CGPoint(x: point.x + self.cellSize, y: point.y - self.cellSize)
        let botLeft  = CGPoint(x: point.x - self.cellSize, y: point.y + self.cellSize)
        let botRight = CGPoint(x: point.x + self.cellSize, y: point.y + self.cellSize)
        return [topLeft, topRight, botLeft, botRight]
    }
}
