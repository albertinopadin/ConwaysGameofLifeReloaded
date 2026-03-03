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
    private let shapeFactory: ShapeFactory
    
    public init(cellSize: CGFloat) {
        // TODO: Need cell dimensions to properly place the points
        //       relative to one another.
        self.cellSize = cellSize
        self.shapeFactory = ShapeFactory(cellSize: cellSize)
    }
    
    public func createSpaceship(at point: CGPoint, type: SpaceshipType) -> [CGPoint] {
        switch type {
        case .Square:
            return shapeFactory.createSquare(at: point)
        case .Glider:
            return createGlider(at: point)
        default:
            return []
        }
    }
    
    public func rotatePoints(_ points: [CGPoint], around center: CGPoint) -> [CGPoint] {
        var rotatedPoints = [CGPoint]()
        points.forEach { p in
            rotatedPoints.append(p.rotate(around: center, degrees: 90.0))
        }
        return rotatedPoints
    }
    
    public func createGlider(at point: CGPoint) -> [CGPoint] {
        let top         = CGPoint(x: point.x, y: point.y - self.cellSize)
        let right       = CGPoint(x: point.x + self.cellSize, y: point.y)
        let bottom      = CGPoint(x: point.x, y: point.y + self.cellSize)
        let bottomLeft  = CGPoint(x: point.x - self.cellSize, y: point.y + self.cellSize)
        let bottomRight = CGPoint(x: point.x + self.cellSize, y: point.y + self.cellSize)
        return [top, right, bottom, bottomLeft, bottomRight]
    }
    
}
