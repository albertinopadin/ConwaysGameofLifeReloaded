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
    
    public let node: SKSpriteNode
    public var neighbors: ContiguousArray<Cell>
    public var liveNeighbors: Int = 0
    public let colorNodeSizeFraction: CGFloat = 0.92
    public let aliveColor: UIColor = .green
    public let deadColor = UIColor(red: 0.16, green: 0.15, blue: 0.30, alpha: 1.0)
    public let shadowColor: UIColor = .darkGray
    
    public let colorAliveAction = SKAction.colorize(with: .green, colorBlendFactor: 1.0, duration: 0.3)
    public let colorDeadAction = SKAction.colorize(with: UIColor(red: 0.16,
                                                                  green: 0.15,
                                                                  blue: 0.30,
                                                                  alpha: 1.0),
                                                    colorBlendFactor: 1.0,
                                                    duration: 0.3)
    
    public let updateNeighborsQueue = DispatchQueue(label: "cgol.update-neighbors.queue", qos: .userInteractive)
    
    public init(frame: CGRect, alive: Bool = false, color: UIColor = .blue) {
        self.currentState = alive ? .Live: .Dead
        self.nextState = self.currentState
        self.neighbors = ContiguousArray<Cell>()
        node = SKSpriteNode(texture: nil,
                   color: color,
                   size: CGSize(width: frame.size.width * colorNodeSizeFraction,
                                height: frame.size.height * colorNodeSizeFraction))
        node.position = frame.origin
        node.blendMode = .replace
        node.physicsBody?.isDynamic = false
    }
    
    @inlinable
    @inline(__always)
    public func makeLive() {
        setLiveState()
        node.color = aliveColor
    }
    
    @inlinable
    @inline(__always)
    public func makeLive(touched: Bool) {
        setLiveState()
        node.run(self.colorAliveAction) { self.node.color = self.aliveColor }
    }
    
    @inlinable
    @inline(__always)
    public func setLiveState() {
        currentState = .Live
        neighbors.forEach {  $0.neighborLive() }
        resetNextState()
    }
    
    
    @inlinable
    @inline(__always)
    public func makeDead() {
        setDeadState()
        node.color = deadColor
    }
    
    @inlinable
    @inline(__always)
    public func makeDead(touched: Bool) {
        setDeadState()
        node.run(self.colorDeadAction) { self.node.color = self.deadColor }
    }
    
    @inlinable
    @inline(__always)
    public func setDeadState() {
        currentState = .Dead
        neighbors.forEach { $0.neighborDied() }
        resetNextState()
    }
    
    @inlinable
    @inline(__always)
    public func alive() -> Bool {
        return currentState == .Live
    }
    
    @inlinable
    @inline(__always)
    public func resetNextState() {
        nextState = currentState
    }
    
    @inlinable
    @inline(__always)
    public func neighborLive() {
        updateNeighborsQueue.sync(flags: .barrier) {
            if liveNeighbors < 8 {
                liveNeighbors += 1
            }
        }
    }
    
    @inlinable
    @inline(__always)
    public func neighborDied() {
        updateNeighborsQueue.sync(flags: .barrier) {
            if liveNeighbors > 0 {
                liveNeighbors -= 1
            }
        }
    }
    
    @inlinable
    @inline(__always)
    public func prepareUpdate() {
        nextState = (currentState == .Live && liveNeighbors == 2) || (liveNeighbors == 3) ? .Live: .Dead
    }
    
    @inlinable
    @inline(__always)
    public func update() {
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
    public func needsUpdate() -> Bool {
        return currentState != nextState
    }
    
    @inlinable
    @inline(__always)
    public func makeShadow() {
        node.color = shadowColor
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
