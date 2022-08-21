//
//  Cell.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 4/15/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import SpriteKit


public struct CellAlpha {
    public static let live: CGFloat = 1.0
    public static let dead: CGFloat = 0.0
}

public struct PrepareUpdateState: Hashable {
    let state: Bool
    let liveNeighbors: Int
    
    public init(state: Bool, liveNeighbors: Int) {
        self.state = state
        self.liveNeighbors = liveNeighbors
    }
}

public final class Cell {
    public final var currentState: Bool
    public final var nextState: Bool
    public final var alive: Bool
    
    public final var neighbors: ContiguousArray<Cell>
    public final var liveNeighbors: Int = 0
    
    public final let node: SKSpriteNode
    public final let shadowColor: SKColor
    public final let colorNodeSizeFraction: CGFloat = 0.92
    
    public final let setLiveAction: SKAction
    public final let setDeadAction: SKAction
    
    public init(frame: CGRect,
                color: SKColor,
                shadowColor: SKColor,
                setLiveAction: SKAction,
                setDeadAction: SKAction,
                alive: Bool = false) {
        self.currentState = alive
        self.nextState = self.currentState
        self.neighbors = ContiguousArray<Cell>()
        self.shadowColor = shadowColor
        self.setLiveAction = setLiveAction
        self.setDeadAction = setDeadAction
        self.alive = alive
        let nodeSize = CGSize(width: frame.size.width * colorNodeSizeFraction,
                              height: frame.size.height * colorNodeSizeFraction)
        node = SKSpriteNode(color: color, size: nodeSize)
        node.position = frame.origin
        node.blendMode = .replace
        node.physicsBody?.isDynamic = false
        
        node.texture?.filteringMode = .nearest
        // Using centerRect makes the quad count higher, which is bad for performance:
        // node.centerRect = CGRect(x: 0.5, y: 0.5, width: 0.0, height: 0.0)
        
        // Using just alpha:
//        node.alpha = CellAlpha.dead
        
        // Using isHidden to hide or show node:
        node.alpha = CellAlpha.live
        node.isHidden = true
    }
    
    @inlinable
    @inline(__always)
    public final func makeLive() {
        setState(live: true)
//        node.alpha = CellAlpha.live
        node.isHidden = false
    }
    
    @inlinable
    @inline(__always)
    public final func makeLiveTouched() {
        setState(live: true)
//        node.run(self.setLiveAction) { self.node.alpha = CellAlpha.live }
        node.run(self.setLiveAction) { self.node.isHidden = false }
        node.isHidden = false
    }
    
    @inlinable
    @inline(__always)
    public final func makeDead() {
        setState(live: false)
//        node.alpha = CellAlpha.dead
        node.isHidden = true
    }
    
    @inlinable
    @inline(__always)
    public final func makeDeadTouched() {
        setState(live: false)
//        node.run(self.setDeadAction) { self.node.alpha = CellAlpha.dead }
        node.run(self.setDeadAction) { self.node.isHidden = true }
        node.isHidden = true
    }
    
    @inlinable
    @inline(__always)
    public final func setState(live: Bool) {
        currentState = live
        alive = currentState
        nextState = currentState
    }
    
    @inlinable
    @inline(__always)
    public final func prepareUpdate() {
        // Lazy helps tremendously as it prevents an intermediate result array from being created
        // For some reason doing this directly is faster than calling the extension:
        liveNeighbors = neighbors.lazy.filter({ $0.alive }).count
        
        if !(!currentState && liveNeighbors < 3) {
            nextState = (currentState && liveNeighbors == 2) || (liveNeighbors == 3)
        }
    }
    
    @inlinable
    @inline(__always)
    public final func update() {
        if needsUpdate() {
            if nextState {
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
