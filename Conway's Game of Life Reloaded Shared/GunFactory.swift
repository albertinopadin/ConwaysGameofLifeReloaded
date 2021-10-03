//
//  GunFactory.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 10/2/21.
//  Copyright © 2021 Albertino Padin. All rights reserved.
//

import SpriteKit


public enum GunType {
    case None,
         Gosper
}


public final class GunFactory {
    private let cellSize: CGFloat
    private let shapeFactory: ShapeFactory
    private let GOSPER_DIMS = CGSize(width: 36, height: 9)
    
    public init(cellSize: CGFloat) {
        self.cellSize = cellSize
        self.shapeFactory = ShapeFactory(cellSize: cellSize)
    }
    
    public func createGun(at point: CGPoint, type: GunType) -> [CGPoint] {
        switch type {
        case .Gosper:
            return createGosperGun(at: point)
        default:
            return []
        }
    }
    
    // Gosper Glider Gun
    // Dimensions: 36 x 9
    public func createGosperGun(at point: CGPoint) -> [CGPoint] {
        let leftSquare = shapeFactory.createSquare(at: CGPoint(x: point.x-GOSPER_DIMS.width/2,
                                                               y: point.y-1))
        let rightSquare = shapeFactory.createSquare(at: CGPoint(x: point.x+GOSPER_DIMS.width/2,
                                                                y: point.y+1))
        
        let mrrPoint = CGPoint(x: point.x+3, y: point.y+1)
        let midRightRectangle = shapeFactory.createRectangle(at: mrrPoint,
                                                             width: 2,
                                                             height: 3)
        
        let midRightRectTop = CGPoint(x: mrrPoint.x+1, y: mrrPoint.y-1)
        let midRightRectBottom = CGPoint(x: mrrPoint.x+1, y: mrrPoint.y+2)
        
        let rightTopPoints = [
            CGPoint(x: midRightRectTop.x+2, y: midRightRectTop.y-1),
            CGPoint(x: midRightRectTop.x+2, y: midRightRectTop.y)
        ]
        
        let rightBottomPoints = [
            CGPoint(x: midRightRectBottom.x+2, y: midRightRectBottom.y),
            CGPoint(x: midRightRectBottom.x+2, y: midRightRectBottom.y+1)
        ]
        
//        let leftC = [
//            
//        ]
        
        var gosperGunPoints = [CGPoint]()
        gosperGunPoints.append(contentsOf: leftSquare)
        gosperGunPoints.append(contentsOf: rightSquare)
        gosperGunPoints.append(contentsOf: midRightRectangle)
        gosperGunPoints.append(contentsOf: rightTopPoints)
        gosperGunPoints.append(contentsOf: rightBottomPoints)
        gosperGunPoints.append(midRightRectTop)
        gosperGunPoints.append(midRightRectBottom)
        
        return gosperGunPoints
    }
    
}
