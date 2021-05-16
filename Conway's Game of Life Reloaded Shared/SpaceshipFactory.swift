//
//  SpaceshipFactory.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 3/16/21.
//  Copyright © 2021 Albertino Padin. All rights reserved.
//


// TODO: Need to figure out how to get into "Put spaceship here" mode
import SpriteKit


public enum SpaceshipType {
    case None,
         Square,
         Glider
}


public final class SpaceshipFactory {
    private let cellSize: CGFloat
    
    public init(cellSize: CGFloat) {
        // TODO: Need cell dimensions to properly place the points
        //       relative to one another.
        self.cellSize = cellSize
    }
    
    public func createSpaceship(at point: CGPoint, type: SpaceshipType) -> [CGPoint] {
        switch type {
        case .Square:
            return createSquare(at: point)
        case .Glider:
            return createGlider(at: point)
        default:
            return []
        }
    }
    
    public func createGlider(at point: CGPoint) -> [CGPoint] {
        let top         = CGPoint(x: point.x, y: point.y - self.cellSize)
        let right       = CGPoint(x: point.x + self.cellSize, y: point.y)
        let bottom      = CGPoint(x: point.x, y: point.y + self.cellSize)
        let bottomLeft  = CGPoint(x: point.x - self.cellSize, y: point.y + self.cellSize)
        let bottomRight = CGPoint(x: point.x + self.cellSize, y: point.y + self.cellSize)
        return [top, right, bottom, bottomLeft, bottomRight]
    }
    
    public func createSquare(at point: CGPoint) -> [CGPoint] {
        // Actually, need to get current cell user clicked in to properly place square...
        let topLeft  = CGPoint(x: point.x - self.cellSize/2, y: point.y - self.cellSize/2)
        let topRight = CGPoint(x: point.x + self.cellSize/2, y: point.y - self.cellSize/2)
        let botLeft  = CGPoint(x: point.x - self.cellSize/2, y: point.y + self.cellSize/2)
        let botRight = CGPoint(x: point.x + self.cellSize/2, y: point.y + self.cellSize/2)
        return [topLeft, topRight, botLeft, botRight]
    }
}
