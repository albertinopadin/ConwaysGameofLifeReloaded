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

public struct PrepareUpdateState: Hashable {
    let state: CellState
    let liveNeighbors: Int
    
    public init(state: CellState, liveNeighbors: Int) {
        self.state = state
        self.liveNeighbors = liveNeighbors
    }
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
    
    public static var prepareUpdateCache: [PrepareUpdateState: CellState] = [
        PrepareUpdateState(state: .Dead, liveNeighbors: 0): .Dead,
        PrepareUpdateState(state: .Dead, liveNeighbors: 1): .Dead,
        PrepareUpdateState(state: .Dead, liveNeighbors: 2): .Dead,
        PrepareUpdateState(state: .Dead, liveNeighbors: 3): .Live,
        PrepareUpdateState(state: .Dead, liveNeighbors: 4): .Dead,
        PrepareUpdateState(state: .Dead, liveNeighbors: 5): .Dead,
        PrepareUpdateState(state: .Dead, liveNeighbors: 6): .Dead,
        PrepareUpdateState(state: .Dead, liveNeighbors: 7): .Dead,
        PrepareUpdateState(state: .Dead, liveNeighbors: 8): .Dead,
        PrepareUpdateState(state: .Live, liveNeighbors: 0): .Dead,
        PrepareUpdateState(state: .Live, liveNeighbors: 1): .Dead,
        PrepareUpdateState(state: .Live, liveNeighbors: 2): .Live,
        PrepareUpdateState(state: .Live, liveNeighbors: 3): .Live,
        PrepareUpdateState(state: .Live, liveNeighbors: 4): .Dead,
        PrepareUpdateState(state: .Live, liveNeighbors: 5): .Dead,
        PrepareUpdateState(state: .Live, liveNeighbors: 6): .Dead,
        PrepareUpdateState(state: .Live, liveNeighbors: 7): .Dead,
        PrepareUpdateState(state: .Live, liveNeighbors: 8): .Dead,
    ]
    
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
        
        if !(currentState == .Dead && liveNeighbors < 3) {
            nextState = (currentState == .Live && liveNeighbors == 2) || (liveNeighbors == 3) ? .Live: .Dead
        }
        
//        nextState = Cell.prepareUpdateCache[PrepareUpdateState(state: currentState, liveNeighbors: liveNeighbors)]!
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
