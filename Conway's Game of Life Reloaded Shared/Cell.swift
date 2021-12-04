//
//  Cell.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 4/15/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import SpriteKit

public enum CellState {
    case Live, Dead
}

public struct CellAlpha {
    public static let live: CGFloat = 1.0
    public static let dead: CGFloat = 0.0
}

public final class Cell {
    public final var currentState: CellState
    public final var nextState: CellState
    public final var alive: Bool
    
    public final var neighbors: ContiguousArray<Cell>
    public final var liveNeighbors: Int = 0
    
    public init(alive: Bool = false) {
        self.currentState = alive ? .Live: .Dead
        self.nextState = self.currentState
        self.neighbors = ContiguousArray<Cell>()
        self.alive = alive
    }
    
    @inlinable
    @inline(__always)
    public final func makeLive() {
        setState(state: .Live)
    }
    
    @inlinable
    @inline(__always)
    public final func makeLiveTouched() {
        setState(state: .Live)
    }
    
    @inlinable
    @inline(__always)
    public final func makeDead() {
        setState(state: .Dead)
    }
    
    @inlinable
    @inline(__always)
    public final func makeDeadTouched() {
        setState(state: .Dead)
    }
    
    @inlinable
    @inline(__always)
    public final func setState(state: CellState) {
//        print("In cell setState: \(state)")
        currentState = state
        alive = currentState == .Live
        nextState = currentState
    }
    
    @inlinable
    @inline(__always)
    public final func prepareUpdate() {
        // Lazy helps tremendously as it prevents an intermediate result array from being created
        // For some reason doing this directly is faster than calling the extension:
        liveNeighbors = neighbors.lazy.filter({ $0.alive }).count
        if !(currentState == .Dead && liveNeighbors < 3) {
            nextState = (currentState == .Live && liveNeighbors == 2) || (liveNeighbors == 3) ? .Live: .Dead
        }
    }
    
    @inlinable
    @inline(__always)
    public final func getUpdate() -> CellState {
        // Lazy helps tremendously as it prevents an intermediate result array from being created
        // For some reason doing this directly is faster than calling the extension:
        liveNeighbors = neighbors.lazy.filter({ $0.alive }).count
        if !(currentState == .Dead && liveNeighbors < 3) {
            nextState = (currentState == .Live && liveNeighbors == 2) || (liveNeighbors == 3) ? .Live: .Dead
            return nextState
        } else {
            return currentState
        }
    }
    
    @inlinable
    @inline(__always)
    public final func needsUpdate() -> Bool {
        return currentState != nextState
    }
}
