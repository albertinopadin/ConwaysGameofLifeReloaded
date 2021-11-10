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

//public struct Cell {
public class Cell {
    public var currentState: CellState
    public var nextState: CellState
    public var neighbors: ContiguousArray<Cell>
    public var liveNeighbors: Int = 0
    public let column: Int
    public let row: Int
    
    public init(column: Int, row: Int, alive: Bool = false) {
        self.column = column
        self.row = row
        self.currentState = alive ? .Live: .Dead
        self.nextState = self.currentState
        self.neighbors = ContiguousArray<Cell>()
    }
    
    @inlinable public func makeLive(touched: Bool = false) {
        currentState = .Live
        neighbors.forEach { $0.neighborLive() }
//        for (index, _) in neighbors.enumerated() {
//            neighbors[index].neighborLive()
//        }
        resetNextState()
        
//        if touched {
//            self.run(self.colorAliveAction) { self.color = self.aliveColor }
//        } else {
//            self.color = self.aliveColor
//        }
    }
    
    @inlinable public func makeDead(touched: Bool = false) {
        currentState = .Dead
        neighbors.forEach { $0.neighborDied() }
//        for (index, _) in neighbors.enumerated() {
//            neighbors[index].neighborDied()
//        }
        resetNextState()
        
//        if touched {
//            self.run(self.colorDeadAction) { self.color = self.deadColor }
//        } else {
//            self.color = self.deadColor
//        }
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
        nextState = (currentState == .Live && liveNeighbors == 2) || (liveNeighbors == 3) ? .Live: .Dead
        
//        switch lastLiveNeighbors {
//        case _ where lastLiveNeighbors < 2:
//            if alive() {
//                nextState = .Dead
//            }
//
//        case 2:
//            break
//
//        case 3:
//            if !alive() {
//                nextState = .Live
//            }
//
//        case _ where lastLiveNeighbors > 3:
//            if alive() {
//                nextState = .Dead
//            }
//
//        default:
//            break
//        }
    }
    
    @inlinable public func update() {
        if needsUpdate() {
            switch nextState {
            case .Live:
                makeLive()
            case .Dead:
                makeDead()
            }
        }
    }
    
    @inlinable public func needsUpdate() -> Bool {
        return currentState != nextState
    }
    
//    @inlinable public mutating func makeShadow() {
//        self.color = shadowColor
//    }
    
}
