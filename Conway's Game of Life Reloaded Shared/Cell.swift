//
//  Cell.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 4/15/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import SpriteKit

#if os(macOS)
public typealias UIColor = NSColor
#endif

public enum CellState {
    case Live, Dead
}

public final class Cell {
    public var currentState: CellState
    public var nextState: CellState
    
    public final let node: SKSpriteNode
    public final var neighbors: ContiguousArray<Cell>
    public var liveNeighbors: Int = 0
    public final let colorNodeSizeFraction: CGFloat = 0.92
    
    public final let aliveColor: SKColor
    public final let deadColor: SKColor
    public final let shadowColor: SKColor
    
    public final let colorAliveAction: SKAction
    public final let colorDeadAction: SKAction
    
    public final let updateNeighborsQueue = DispatchQueue(label: "cgol.update-neighbors.queue",
                                                          qos: .userInteractive)
    
    public init(frame: CGRect,
                liveColor: SKColor,
                deadColor: SKColor,
                shadowColor: SKColor,
                colorAliveAction: SKAction,
                colorDeadAction: SKAction,
                alive: Bool = false,
                color: UIColor = .clear) {
        self.currentState = alive ? .Live: .Dead
        self.nextState = self.currentState
        self.neighbors = ContiguousArray<Cell>()
        self.aliveColor = liveColor
        self.deadColor = deadColor
        self.shadowColor = shadowColor
        self.colorAliveAction = colorAliveAction
        self.colorDeadAction = colorDeadAction
        node = SKSpriteNode(texture: nil,
                            color: deadColor,
                            size: CGSize(width: frame.size.width * colorNodeSizeFraction,
                                         height: frame.size.height * colorNodeSizeFraction))
        node.position = frame.origin
        node.blendMode = .replace
        node.physicsBody?.isDynamic = false
        
        node.texture?.filteringMode = .nearest
//        node.centerRect = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
//        node.centerRect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        node.centerRect = CGRect(x: 1.0, y: 1.0, width: 0.0, height: 0.0)
//        node.centerRect = CGRect(x: 0.5, y: 0.5, width: 0.0, height: 0.0)
    }
    
    @inlinable
    @inline(__always)
    public final func makeLive() {
        setLiveState()
        node.color = aliveColor
    }
    
    @inlinable
    @inline(__always)
    public final func makeLiveTouched() {
        setLiveState()
        node.run(self.colorAliveAction) { self.node.color = self.aliveColor }
    }
    
    @inlinable
    @inline(__always)
    public final func setLiveState() {
        currentState = .Live
        neighbors.forEach {  $0.neighborLive() }
        resetNextState()
    }
    
    
    @inlinable
    @inline(__always)
    public final func makeDead() {
        setDeadState()
        node.color = deadColor
    }
    
    @inlinable
    @inline(__always)
    public final func makeDeadTouched() {
        setDeadState()
        node.run(self.colorDeadAction) { self.node.color = self.deadColor }
    }
    
    @inlinable
    @inline(__always)
    public final func setDeadState() {
        currentState = .Dead
        neighbors.forEach { $0.neighborDied() }
        resetNextState()
    }
    
    @inlinable
    @inline(__always)
    public final func alive() -> Bool {
        return currentState == .Live
    }
    
    @inlinable
    @inline(__always)
    public final func resetNextState() {
        nextState = currentState
    }
    
    @inlinable
    @inline(__always)
    public final func neighborLive() {
        updateNeighborsQueue.sync(flags: .barrier) {
            if liveNeighbors < 8 {
                liveNeighbors += 1
            }
        }
    }
    
    @inlinable
    @inline(__always)
    public final func neighborDied() {
        updateNeighborsQueue.sync(flags: .barrier) {
            if liveNeighbors > 0 {
                liveNeighbors -= 1
            }
        }
    }
    
    @inlinable
    @inline(__always)
    public final func prepareUpdate() {
        nextState = (currentState == .Live && liveNeighbors == 2) || (liveNeighbors == 3) ? .Live: .Dead
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
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
