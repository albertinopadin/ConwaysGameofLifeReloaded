//
//  Cell.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 4/15/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import SpriteKit
import RxSwift
import RxRelay

#if os(macOS)
public typealias UIColor = NSColor
#endif

public final class Cell: SKSpriteNode {
    public var alive: Bool
    public var liveNeighbors: Int = 0
    private let aliveRelay = BehaviorRelay<Bool>(value: false)
    public var isAlive: Observable<Bool> { return aliveRelay.asObservable() }
    private let disposeBag = DisposeBag()
    public var neighbors = ContiguousArray<Cell>() {
        willSet {
            DispatchQueue.global(qos: .userInteractive).async {
                for n in newValue {
                    _ = n.isAlive.subscribeOn(CurrentThreadScheduler.instance
                    ).observeOn(CurrentThreadScheduler.instance
                    ).scan([], accumulator: { lastSlice, newValue in
                        return Array(lastSlice + [newValue]).suffix(2)
                    }).subscribe(onNext: { [unowned self] slice in
                        let oldValue = slice.first!
                        let newValue = slice.last!
                        if Cell.becameAlive(alivePrevious: oldValue, aliveCurrent: newValue) {
                            self.liveNeighbors += 1
                        } else if Cell.becameDead(alivePrevious: oldValue, aliveCurrent: newValue) {
                            self.liveNeighbors -= 1
                        }
                    }).disposed(by: self.disposeBag)
                }
            }
        }
    }
    
    private static func becameAlive(alivePrevious: Bool, aliveCurrent: Bool) -> Bool {
        return !alivePrevious && aliveCurrent
    }
    
    private static func becameDead(alivePrevious: Bool, aliveCurrent: Bool) -> Bool {
        return alivePrevious && !aliveCurrent
    }
    
    private let colorNodeSizeFraction: CGFloat = 0.9
    private let aliveColor: UIColor = .green
    private let deadColor = UIColor(red: 0.16, green: 0.15, blue: 0.30, alpha: 1.0)
    
    public init(frame: CGRect, alive: Bool = false, color: UIColor = .blue) {
        self.alive = alive
        super.init(texture: nil,
                   color: color,
                   size: CGSize(width: frame.size.width * colorNodeSizeFraction,
                                height: frame.size.height * colorNodeSizeFraction))
        position = frame.origin
        self.blendMode = .replace
    }
    
    public func makeLive() {
        alive = true
        self.color = aliveColor
        aliveRelay.accept(true)
    }
    
    public func makeDead() {
        alive = false
        self.color = deadColor
        aliveRelay.accept(false)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
