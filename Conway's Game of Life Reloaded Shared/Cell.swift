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

public class Cell: SKSpriteNode {
    
    public var alive: Bool
    private var colorNode: SKSpriteNode
    private let colorNodeSizeFraction: CGFloat = 0.9
    
    public init(frame: CGRect, alive: Bool = false, color: UIColor = .blue) {
        self.alive = alive
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
        self.colorNode.color = .green
    }
    
    public func makeDead() {
        self.alive = false
        self.colorNode.color = UIColor(red: 0.16, green: 0.15, blue: 0.30, alpha: 1.0)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
