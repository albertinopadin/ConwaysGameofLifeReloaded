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

public final class Cell: SKSpriteNode {
    public var currentState: CellState
    public var nextState: CellState
    
    public var neighbors: ContiguousArray<Cell>
    public var liveNeighbors: Int = 0
    public var lastLiveNeighbors: Int = 0
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
    
    public init(frame: CGRect, alive: Bool = false, color: UIColor = .blue) {
        self.currentState = alive ? .Live: .Dead
        self.nextState = self.currentState
        self.neighbors = ContiguousArray<Cell>()
        super.init(texture: nil,
                   color: color,
                   size: CGSize(width: frame.size.width * colorNodeSizeFraction,
                                height: frame.size.height * colorNodeSizeFraction))
        self.position = frame.origin
        self.blendMode = .replace
        self.physicsBody?.isDynamic = false
    }
    
    @inlinable public func makeLive(touched: Bool = false) {
        currentState = .Live
        neighbors.forEach {
            $0.neighborLive()
        }
        resetNextState()
        
        if touched {
            self.run(self.colorAliveAction) { self.color = self.aliveColor }
        } else {
            self.color = self.aliveColor
        }
    }
    
    @inlinable public func makeDead(touched: Bool = false) {
        currentState = .Dead
        neighbors.forEach {
            $0.neighborDied()
        }
        resetNextState()
        
        if touched {
            self.run(self.colorDeadAction) { self.color = self.deadColor }
        } else {
            self.color = self.deadColor
        }
    }
    
    @inlinable public func alive() -> Bool {
        return currentState == .Live
    }
    
    @inlinable public func resetNextState() {
        nextState = currentState
    }
    
    @inlinable public func neighborLive() {
        if liveNeighbors < 8 {
            liveNeighbors += 1
        }
    }
    
    @inlinable public func neighborDied() {
        if liveNeighbors > 0 {
            liveNeighbors -= 1
        }
    }
    
    @inlinable public func prepareUpdate() {
        lastLiveNeighbors = liveNeighbors
        switch lastLiveNeighbors {
        case _ where lastLiveNeighbors < 2:
            if alive() {
                nextState = .Dead
            }

        case 2:
            break

        case 3:
            if !alive() {
                nextState = .Live
            }

        case _ where lastLiveNeighbors > 3:
            if alive() {
                nextState = .Dead
            }

        default:
            break
        }
    }
    
    @inlinable public func update() {
        if currentState != nextState {
            switch nextState {
            case .Live:
                makeLive()
            case .Dead:
                makeDead()
            }
        }
    }
    
    @inlinable public func makeShadow() {
        self.color = shadowColor
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
