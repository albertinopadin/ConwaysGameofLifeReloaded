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

public final class Cell: SKSpriteNode {
    public var alive: Bool
    public var shouldLive: Bool
    public var shouldDie: Bool
    public var neighbors: ContiguousArray<Cell>
    public var liveNeighbors: Int = 0
    public var lastLiveNeighbors: Int = 0
    private let colorNodeSizeFraction: CGFloat = 0.92
    private let aliveColor: UIColor = .green
    private let deadColor = UIColor(red: 0.16, green: 0.15, blue: 0.30, alpha: 1.0)
    private let shadowColor: UIColor = .darkGray
    
    private let colorAliveAction = SKAction.colorize(with: .green, colorBlendFactor: 1.0, duration: 0.3)
    private let colorDeadAction = SKAction.colorize(with: UIColor(red: 0.16,
                                                                  green: 0.15,
                                                                  blue: 0.30,
                                                                  alpha: 1.0),
                                                    colorBlendFactor: 1.0,
                                                    duration: 0.3)
    
    public init(frame: CGRect, alive: Bool = false, color: UIColor = .blue) {
        self.alive = alive
        self.shouldLive = false
        self.shouldDie = false
        self.neighbors = ContiguousArray<Cell>()
        super.init(texture: nil,
                   color: color,
                   size: CGSize(width: frame.size.width * colorNodeSizeFraction,
                                height: frame.size.height * colorNodeSizeFraction))
        self.position = frame.origin
        self.blendMode = .replace
    }
    
    public func makeLive(touched: Bool = false) {
        alive = true
        neighbors.forEach {
            $0.neighborLive()
        }
        resetShould()
        
        if touched {
            self.run(self.colorAliveAction) { self.color = self.aliveColor }
        } else {
            self.color = self.aliveColor
        }
    }
    
    public func makeDead(touched: Bool = false) {
        alive = false
        neighbors.forEach {
            $0.neighborDied()
        }
        resetShould()
        
        if touched {
            self.run(self.colorDeadAction) { self.color = self.deadColor }
        } else {
            self.color = self.deadColor
        }
    }
    
    public func updateLastGenLiveNeighbors() {
        liveNeighbors = neighbors.filter({ $0.alive }).count
    }
    
    public func neighborLive() {
        if liveNeighbors < 8 {
            liveNeighbors += 1
        }
    }
    
    public func neighborDied() {
        if liveNeighbors > 0 {
            liveNeighbors -= 1
        }
    }
    
    func shouldBeLive() {
        shouldLive = true
        shouldDie = false
    }
    
    func shouldBeDead() {
        shouldDie = true
        shouldLive = false
    }
    
    func resetShould() {
        shouldLive = false
        shouldDie = false
    }
    
    public func snapshotLiveNeighbors() {
        lastLiveNeighbors = liveNeighbors
        switch lastLiveNeighbors {
        case _ where lastLiveNeighbors < 2:
            if alive {
                shouldBeDead()
            }

        case 2:
            break

        case 3:
            if !alive {
                shouldBeLive()
            }

        case _ where lastLiveNeighbors > 3:
            if alive {
                shouldBeDead()
            }

        default:
            break
        }
    }
    
    public func makeShadow() {
        self.color = shadowColor
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
