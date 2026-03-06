//
//  CellGrid.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 4/15/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import SpriteKit


final class CellGrid {
    let xCount: Int
    let yCount: Int
    let quadCountX: Int
    let quadCountY: Int
    let updateQueue = DispatchQueue(label: "cgol.update.queue",
                                    qos: .userInteractive)
    final var grid = ContiguousArray<ContiguousArray<Cell>>()   // 2D Array to hold the cells
    let algorithm: LifeAlgorithm
    var cellSize: CGFloat = 23.0
    var generation: UInt64 = 0
    var spaceshipFactory: SpaceshipFactory?
    var shadowed = [Cell]()
    
    final let userInputQueue = DispatchQueue(label: "cgol.userInput.queue",
                                             qos: .userInteractive)
    
    final let aliveColor: SKColor = .green
    final let deadColor = SKColor(red: 0.16, green: 0.15, blue: 0.30, alpha: 1.0)
    final let shadowColor: SKColor = .darkGray
    
    final let liveAction = SKAction.unhide()
    final let deadAction = SKAction.hide()
    
    
    init(xCells: Int, yCells: Int, cellSize: CGFloat) {
        xCount = xCells
        yCount = yCells
        quadCountX = Int(xCells/4)
        quadCountY = Int(yCells/4)
        self.cellSize = cellSize
        // Consider using a configuration struct:
        grid = Self.makeGrid(xCells: xCells,
                             yCells: yCells,
                             cellSize: cellSize,
                             aliveColor: aliveColor,
                             shadowColor: shadowColor,
                             liveAction: liveAction,
                             deadAction: deadAction)
//        algorithm = NaiveConcurrent(grid: grid, xCount: xCount, yCount: yCount, queue: updateQueue)
        algorithm = Hashlife(grid: grid, xCount: xCount, yCount: yCount, queue: updateQueue)
        setNeighborsForAllCellsInGrid()
        spaceshipFactory = SpaceshipFactory(cellSize: cellSize)
    }
    
    static func makeGrid(xCells: Int,
                         yCells: Int,
                         cellSize: CGFloat,
                         aliveColor: SKColor,
                         shadowColor: SKColor,
                         liveAction: SKAction,
                         deadAction: SKAction) -> ContiguousArray<ContiguousArray<Cell>> {
        let initialCell = Cell(frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                               color: aliveColor,
                               shadowColor: shadowColor,
                               setLiveAction: liveAction,
                               setDeadAction: deadAction)
        let newGridRow = ContiguousArray<Cell>(repeating: initialCell, count: yCells)
        var newGrid = ContiguousArray<ContiguousArray<Cell>>(repeating: newGridRow, count: xCells)

        for x in 0..<xCells {
            for y in 0..<yCells {
                // The x and y coords are not at the edge of the cell; instead they are the center of it.
                // This can create confusion when attempting to position cells!

                // For adding directly to scene:
                let cellFrame = CGRect(x: cellMiddle(iteration: x, length: cellSize),
                                       y: cellMiddle(iteration: y, length: cellSize),
                                       width: cellSize,
                                       height: cellSize)

                newGrid[x][y] = Cell(frame: cellFrame,
                                     color: aliveColor,
                                     shadowColor: shadowColor,
                                     setLiveAction: liveAction,
                                     setDeadAction: deadAction)
            }
        }
        return newGrid
    }
    
    // Returns the middle coordinate given an iteration and a length
    // Example: If the cell is in iteration 0 and the length of a side
    // of the cell is 4, the cell middle would be 2.
    // Useful to position cells by their center point
    private static func cellMiddle(iteration: Int, length: CGFloat) -> CGFloat {
        return (CGFloat(iteration) * length) + length/2
    }
    
    private func setNeighborsForAllCellsInGrid() {
        for x in 0..<xCount {
            for y in 0..<yCount {
                grid[x][y].neighbors = getCellNeighbors(x: x, y: y)
            }
        }
    }
    
    private func getCellNeighbors(x: Int, y: Int) -> ContiguousArray<Cell> {
        var neighbors = ContiguousArray<Cell>()
        
        // Get the neighbors:
        let leftX   = x - 1
        let rightX  = x + 1
        let topY    = y + 1
        let bottomY = y - 1
        
        let leftNeighbor        = leftX > -1 ? grid[leftX][y] : nil
        let upperLeftNeighbor   = leftX > -1 && topY < yCount ? grid[leftX][topY] : nil
        let upperNeighbor       = topY < yCount ? grid[x][topY] : nil
        let upperRightNeighbor  = rightX < xCount && topY < yCount ? grid[rightX][topY] : nil
        let rightNeighbor       = rightX < xCount ? grid[rightX][y] : nil
        let lowerRightNeighbor  = rightX < xCount && bottomY > -1 ? grid[rightX][bottomY] : nil
        let lowerNeighbor       = bottomY > -1 ? grid[x][bottomY] : nil
        let lowerLeftNeighbor   = leftX > -1 && bottomY > -1 ? grid[leftX][bottomY] : nil
        
        if let left_n = leftNeighbor {
            neighbors.append(left_n)
        }
        
        if let upper_left_n = upperLeftNeighbor {
            neighbors.append(upper_left_n)
        }
        
        if let upper_n = upperNeighbor {
            neighbors.append(upper_n)
        }
        
        if let upper_right_n = upperRightNeighbor {
            neighbors.append(upper_right_n)
        }
        
        if let right_n = rightNeighbor {
            neighbors.append(right_n)
        }
        
        if let lower_right_n = lowerRightNeighbor {
            neighbors.append(lower_right_n)
        }
        
        if let lower_n = lowerNeighbor {
            neighbors.append(lower_n)
        }
        
        if let lower_left_n = lowerLeftNeighbor {
            neighbors.append(lower_left_n)
        }
        
        return neighbors
    }
    
    // Update cells using Conway's Rules of Life:
    // 1) Any live cell with fewer than two live neighbors dies (underpopulation)
    // 2) Any live cell with two or three live neighbors lives on to the next generation
    // 3) Any live cell with more than three live neighbors dies (overpopulation)
    // 4) Any dead cell with exactly three live neighbors becomes a live cell (reproduction)
    // Must apply changes all at once for each generation, so will need copy of current cell grid
    @inlinable
    @inline(__always)
    final func updateCells() -> UInt64 {
        generation = algorithm.update(generation: generation)
        return generation
    }

    func getGridIndicesFromPoint(at: CGPoint) -> (x: Int, y: Int) {
        let xIndex = Int(at.x / cellSize)
        let yIndex = Int(at.y / cellSize)
        
        return (xIndex, yIndex)
    }
        
    // TODO: Fix index out of bounds bug here:
    @inlinable
    @inline(__always)
    final func touchedCell(at: CGPoint, gameRunning: Bool, withAltAction: Bool = false) {
        // Find the cell that contains the touch point and make it live:
        let t = timeit {
            let x = Int(at.x / cellSize)
            let y = Int(at.y / cellSize)

            let cell = grid[x][y]
            
            if !withAltAction && !cell.alive {
                userInputQueue.sync(flags: .barrier) {
                    if gameRunning {
                        cell.makeLive()
                    } else {
                        cell.makeLiveTouched()
                    }
                }
            } else if withAltAction && cell.alive {
                userInputQueue.sync(flags: .barrier) {
                    if gameRunning {
                        cell.makeDead()
                    } else {
                        cell.makeDeadTouched()
                    }
                }
            }
        }
        print("Run time for touchedCell: \(Double(t)/1_000_000) ms")
    }
    
    // To create spaceships:
    func createPattern(with points: [CGPoint]) {
        for p in points {
            let x = Int(p.x / cellSize)
            let y = Int(p.y / cellSize)

            let cell = grid[x][y]
            cell.makeLive()
        }
    }
    
    func resetShadowed() {
        for cell in shadowed {
            cell.node.color = .blue
        }
        shadowed.removeAll()
    }
    
    func shadowPattern(with points: [CGPoint]) {
        for p in points {
            let x = Int(p.x / cellSize)
            let y = Int(p.y / cellSize)

            let cell = grid[x][y]
            if !cell.alive {
                cell.makeShadow()
                shadowed.append(cell)
            }
        }
    }
    
    func getPointDimensions() -> (CGFloat, CGFloat) {
        return (getPointWidth(), getPointHeight())
    }
    
    func getPointWidth() -> CGFloat {
        return CGFloat(xCount) * cellSize
    }
    
    func getPointHeight() -> CGFloat {
        return CGFloat(yCount) * cellSize
    }
    
    final func reset() {
        // Reset the game to initial state with no cells alive:
        updateQueue.sync(flags: .barrier) {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                    self.grid[x][y].makeDead()
                }
            }
        }
        
//        grid.lazy.joined().forEach({ $0.makeDead() })
        
        generation = 0
    }
    
    func shadowSpaceship(at point: CGPoint, type: SpaceshipType) {
        resetShadowed()
        let spaceshipPoints = spaceshipFactory!.createSpaceship(at: point, type: type)
        shadowPattern(with: spaceshipPoints)
    }
    
    func placeSpaceship(at point: CGPoint, type: SpaceshipType) {
        resetShadowed()
        let spaceshipPoints = spaceshipFactory!.createSpaceship(at: point, type: type)
        createPattern(with: spaceshipPoints)
    }
    
    final func randomState(liveProbability: Double) {
        reset()
        if liveProbability == 1.0 {
            makeAllLive()
        } else {
            if liveProbability > 0.0 {
                let liveProb = Int(liveProbability*100)
                updateQueue.sync {
                    DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                        DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                            let randInt = Int.random(in: 0...100)
                            if randInt <= liveProb {
                                self.grid[x][y].makeLive()
                            }
                        }
                    }
                }
                
//                grid.lazy.joined().forEach { cell in
//                    let randInt = Int.random(in: 0...100)
//                    if randInt <= liveProb {
//                        cell.makeLive()
//                    }
//                }
            }
        }
        
        algorithm.synchronizeState()
    }
    
    final func makeAllLive() {
        updateQueue.sync {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                    self.grid[x][y].makeLive()
                }
            }
        }
    }
    
}
