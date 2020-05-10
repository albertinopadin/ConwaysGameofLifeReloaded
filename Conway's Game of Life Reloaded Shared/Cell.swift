//
//  Cell.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 4/15/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import SpriteKit
import RxSwift

#if os(macOS)
public typealias UIColor = NSColor
#endif

struct BoolSeq {
    var oldValue: Bool = false
    var newValue: Bool = false
}

public final class Cell: SKSpriteNode {
    
    public var alive: Bool
    public var liveNeighbors: Int = 0
    public var neighbors = ContiguousArray<Cell>() {
        willSet {
            for n in newValue {
                _ = n.isAlive.scan([], accumulator: { lastSlice, newValue in
                    return Array(lastSlice + [newValue]).suffix(2)
                }).subscribe(onNext: { [weak self] slice in
                    let oldValue = slice.first!
                    let newValue = slice.last!
                    if !oldValue && newValue {
                        self!.liveNeighbors += 1
                    } else if oldValue && !newValue {
                        self!.liveNeighbors -= 1
                    }
                }).disposed(by: disposeBag)
            }
        }
    }
    public var lastGenLiveNeighbors: Int = 0
    private var colorNode: SKSpriteNode
    
    private let colorNodeSizeFraction: CGFloat = 0.9
    private let aliveColor: UIColor = .green
    private let deadColor = UIColor(red: 0.16, green: 0.15, blue: 0.30, alpha: 1.0)
    
    private let aliveVariable = Variable<Bool>(false)
    var isAlive: Observable<Bool> { return aliveVariable.asObservable() }
    let disposeBag = DisposeBag()
    
    public init(frame: CGRect, alive: Bool = false, color: UIColor = .blue) {
        self.alive = alive
//        neighbors = ContiguousArray<Cell>()
        colorNode = SKSpriteNode(color: color,
                                 size: CGSize(width: frame.size.width * colorNodeSizeFraction,
                                              height: frame.size.height * colorNodeSizeFraction))
        colorNode.position = CGPoint.zero
        
        super.init(texture: nil, color: .black, size: frame.size)
        position = frame.origin
        self.addChild(colorNode)
    }
    
    public func makeLive() {
        alive = true
        colorNode.color = aliveColor
        aliveVariable.value = true
    }
    
    public func makeDead() {
        alive = false
        colorNode.color = deadColor
        aliveVariable.value = false
    }
    
    public func updateLastGenLiveNeigbors() {
        lastGenLiveNeighbors = neighbors.filter({$0.alive}).count
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
