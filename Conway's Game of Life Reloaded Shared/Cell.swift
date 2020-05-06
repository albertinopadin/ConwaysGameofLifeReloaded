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
    private var colorNode: SKSpriteNode
    
    private let colorNodeSizeFraction: CGFloat = 0.9
    private let aliveColor: UIColor = .green
    private let deadColor = UIColor(red: 0.16, green: 0.15, blue: 0.30, alpha: 1.0)
    
    public init(frame: CGRect, alive: Bool = false, color: UIColor = .blue) {
        self.alive = alive
        self.neighbors = ContiguousArray<Cell>()
        self.colorNode = SKSpriteNode(color: color,
                                      size: CGSize(width: frame.size.width * colorNodeSizeFraction,
                                                   height: frame.size.height * colorNodeSizeFraction))
        self.colorNode.position = CGPoint.zero
        
        super.init(texture: nil, color: .black, size: frame.size)
        self.position = frame.origin
        self.addChild(self.colorNode)
        
    }
    
    public func makeLive() {
        self.alive = true
        self.colorNode.color = aliveColor
    }
    
    public func makeDead() {
        self.alive = false
        self.colorNode.color = deadColor
    }
    
    public func updateLastGenLiveNeigbors() {
        lastGenLiveNeighbors = neighbors.filter({$0.alive}).count
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
