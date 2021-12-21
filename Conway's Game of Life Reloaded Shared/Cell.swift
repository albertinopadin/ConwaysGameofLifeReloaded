//
//  Cell.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 4/15/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import SpriteKit

public enum CellState {
    case Live, Dead
}

public struct CellAlpha {
    public static let live: CGFloat = 1.0
    public static let dead: CGFloat = 0.0
}

public final class Cell {
    public final var currentState: CellState
    public final var nextState: CellState
    public final var alive: Bool
    
    public final var neighbors: ContiguousArray<Cell>
    public final var liveNeighbors: Int = 0
    
    public final let node: SKSpriteNode
    public final let shadowColor: SKColor
    public final let colorNodeSizeFraction: CGFloat = 0.92
    
    public final let colorAliveAction: SKAction
    public final let colorDeadAction: SKAction
    
    public final let cellUpdateQueue = DispatchQueue(label: "cgol.update.cell.queue",
                                                     qos: .userInteractive,
                                                     attributes: .concurrent)
    
    public init(frame: CGRect,
                color: SKColor,
                shadowColor: SKColor,
                colorAliveAction: SKAction,
                colorDeadAction: SKAction,
                alive: Bool = false) {
        self.currentState = alive ? .Live: .Dead
        self.nextState = self.currentState
        self.neighbors = ContiguousArray<Cell>()
        self.shadowColor = shadowColor
        self.colorAliveAction = colorAliveAction
        self.colorDeadAction = colorDeadAction
        self.alive = alive
        node = SKSpriteNode(texture: nil,
                            color: color,
                            size: CGSize(width: frame.size.width * colorNodeSizeFraction,
                                         height: frame.size.height * colorNodeSizeFraction))
        node.position = frame.origin
        node.blendMode = .replace
        node.physicsBody?.isDynamic = false
        
        node.texture?.filteringMode = .nearest
        node.centerRect = CGRect(x: 0.5, y: 0.5, width: 0.0, height: 0.0)
        node.alpha = CellAlpha.dead
    }
    
    @inlinable
    @inline(__always)
    public final func makeLive() {
        setState(state: .Live)
        node.alpha = CellAlpha.live
    }
    
    @inlinable
    @inline(__always)
    public final func makeLiveTouched() {
        setState(state: .Live)
//        node.run(self.colorAliveAction) { self.node.alpha = CellAlpha.live }
        self.node.alpha = CellAlpha.live
    }
    
    @inlinable
    @inline(__always)
    public final func makeDead() {
        setState(state: .Dead)
        node.alpha = CellAlpha.dead
    }
    
    @inlinable
    @inline(__always)
    public final func makeDeadTouched() {
        setState(state: .Dead)
//        node.run(self.colorDeadAction) { self.node.alpha = CellAlpha.dead }
        self.node.alpha = CellAlpha.dead
    }
    
    @inlinable
    @inline(__always)
    public final func setState(state: CellState) {
        currentState = state
        alive = currentState == .Live
        nextState = currentState
    }
    
    @inlinable
    @inline(__always)
    public final func prepareUpdate() {
        // Lazy helps tremendously as it prevents an intermediate result array from being created
        // For some reason doing this directly is faster than calling the extension:
        liveNeighbors = neighbors.lazy.filter({ $0.alive }).count
        
//        liveNeighbors = 0
//        for cell in neighbors where cell.alive {
//            liveNeighbors += 1
////            if liveNeighbors > 3 {
////                break
////            }
//        }
        
//        liveNeighbors = neighbors.lazy.filter({ $0.alive() }).prefix(4).count
//        liveNeighbors = neighbors.lazy.filter({ $0.currentState == .Live }).count
//        liveNeighbors = neighbors.count(where: { $0.alive() })
//        liveNeighbors = neighbors.lazy.map({ $0.alive() ? 1: 0 }).reduce(0, +)
//        liveNeighbors = neighbors.lazy.reduce(0, { $0 + ($1.alive() ? 1: 0) })
        if !(currentState == .Dead && liveNeighbors < 3) {
            nextState = (currentState == .Live && liveNeighbors == 2) || (liveNeighbors == 3) ? .Live: .Dead
        }
    }
    
    @inlinable
    @inline(__always)
    public final func update() {
        if needsUpdate() {
            if nextState == .Live {
                makeLive()
            } else {
                makeDead()
            }
        }
    }
    
    @inlinable
    @inline(__always)
    public final func needsUpdate() -> Bool {
        return currentState != nextState
    }
    
    @inlinable
    @inline(__always)
    public final func makeShadow() {
        node.color = shadowColor
    }
}
