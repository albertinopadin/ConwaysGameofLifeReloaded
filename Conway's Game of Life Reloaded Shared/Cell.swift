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
    public var neighbors: ContiguousArray<Cell>
    public var lastGenLiveNeighbors: Int = 0
    private let colorNodeSizeFraction: CGFloat = 0.92
    private let aliveColor: UIColor = .green
    private let deadColor = UIColor(red: 0.16, green: 0.15, blue: 0.30, alpha: 1.0)
    
    private let colorAliveAction = SKAction.colorize(with: .green, colorBlendFactor: 1.0, duration: 0.3)
    private let colorDeadAction = SKAction.colorize(with: UIColor(red: 0.16,
                                                                  green: 0.15,
                                                                  blue: 0.30,
                                                                  alpha: 1.0),
                                                    colorBlendFactor: 1.0,
                                                    duration: 0.3)
    
    public init(frame: CGRect, alive: Bool = false, color: UIColor = .blue) {
        self.alive = alive
        self.neighbors = ContiguousArray<Cell>()
        super.init(texture: nil,
                   color: color,
                   size: CGSize(width: frame.size.width * colorNodeSizeFraction,
                                height: frame.size.height * colorNodeSizeFraction))
        self.position = frame.origin
        self.blendMode = .replace
    }
    
    public func makeLive(touched: Bool = false) {
        self.alive = true
        if touched {
            self.run(colorAliveAction) { self.color = self.aliveColor }
        } else {
            self.color = aliveColor
        }
    }
    
    public func makeDead(touched: Bool = false) {
        self.alive = false
        if touched {
            self.run(colorDeadAction) { self.color = self.deadColor }
        } else {
            self.color = deadColor
        }
    }
    
    public func updateLastGenLiveNeigbors() {
        lastGenLiveNeighbors = neighbors.filter({ $0.alive }).count
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
