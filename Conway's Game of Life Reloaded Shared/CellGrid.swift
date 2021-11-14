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
    let quarterCountX: Int
    let quarterCountY: Int
    var grid = ContiguousArray<ContiguousArray<Cell>>()   // 2D Array to hold the cells
    var cellSize: CGFloat = 23.0
    var generation: UInt64 = 0
    var spaceshipFactory: SpaceshipFactory?
    var shadowed = [Cell]()
    let updateQueue = DispatchQueue(label: "cgol.update.queue", qos: .userInteractive, attributes: .concurrent)
    
    init(xCells: Int, yCells: Int, cellSize: CGFloat) {
        xCount = xCells
        yCount = yCells
        quarterCountX = xCount / 4
        quarterCountY = yCount / 4
        self.cellSize = cellSize
        grid = makeGrid(xCells: xCells, yCells: yCells)
        setNeighborsForAllCellsInGrid()
        spaceshipFactory = SpaceshipFactory(cellSize: cellSize)
    }
    
    func makeGrid(xCells: Int, yCells: Int) -> ContiguousArray<ContiguousArray<Cell>> {
        let initialCell = Cell(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        let newGridRow = ContiguousArray<Cell>(repeating: initialCell, count: yCells)
        var newGrid = ContiguousArray<ContiguousArray<Cell>>(repeating: newGridRow, count: xCells)
        
        // For adding to backing node:
        let totalSize = CGSize(width: CGFloat(xCells)*cellSize, height: CGFloat(yCells)*cellSize)
        let xOffset = totalSize.width/2
        let yOffset = totalSize.height/2
        for x in 0..<xCells {
            for y in 0..<yCells {
                // The x and y coords are not at the edge of the cell; instead they are the center of it.
                // This can create confusion when attempting to position cells!
                
                // For adding directly to scene:
//                let cellFrame = CGRect(x: cellMiddle(iteration: x, length: cellSize),
//                                       y: cellMiddle(iteration: y, length: cellSize),
//                                       width: cellSize,
//                                       height: cellSize)
                
                // For adding to backing node:
                let cellFrame = CGRect(x: cellMiddle(iteration: x, length: cellSize) - xOffset,
                                       y: cellMiddle(iteration: y, length: cellSize) - yOffset,
                                       width: cellSize,
                                       height: cellSize)
                newGrid[x][y] = Cell(frame: cellFrame)
            }
        }
        return newGrid
    }
    
    // Returns the middle coordinate given an iteration and a length
    // Example: If the cell is in iteration 0 and the length of a side
    // of the cell is 4, the cell middle would be 2.
    // Useful to position cells by their center point
    private func cellMiddle(iteration: Int, length: CGFloat) -> CGFloat {
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
        let upperLeftNeighbor   = leftX > -1 && topY < (grid.first?.count)! ? grid[leftX][topY] : nil
        let upperNeighbor       = topY < (grid.first?.count)! ? grid[x][topY] : nil
        let upperRightNeighbor  = rightX < grid.count && topY < (grid.first?.count)! ? grid[rightX][topY] : nil
        let rightNeighbor       = rightX < grid.count ? grid[rightX][y] : nil
        let lowerRightNeighbor  = rightX < grid.count && bottomY > -1 ? grid[rightX][bottomY] : nil
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
    
//    @inlinable func prepareUpdateCells() {
//        // Prepare update:
//        DispatchQueue.global(qos: .userInteractive).sync {
//            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
//                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
//                    self.grid[x][y].prepareUpdate()
//                }
//            }
//        }
//    }
    
    // Update cells using Conway's Rules of Life:
    // 1) Any live cell with fewer than two live neighbors dies (underpopulation)
    // 2) Any live cell with two or three live neighbors lives on to the next generation
    // 3) Any live cell with more than three live neighbors dies (overpopulation)
    // 4) Any dead cell with exactly three live neighbors becomes a live cell (reproduction)
    // Must apply changes all at once for each generation, so will need copy of current cell grid
    @inlinable
    @inline(__always)
    func updateCells() -> UInt64 {
        // Prepare update:
        updateQueue.sync(flags: .barrier) {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                    self.grid[x][y].prepareUpdate()
                }
            }
        }
        
//        updateQueue.sync(flags: .barrier) {
//            DispatchQueue.concurrentPerform(iterations: self.quarterCountX) { x in
////                DispatchQueue.concurrentPerform(iterations: self.quarterCountY) { y in
////                    self.grid[x][y].prepareUpdate()
////
////                    self.grid[x + self.quarterCountX][y].prepareUpdate()
////                    self.grid[x][y + self.quarterCountY].prepareUpdate()
////                    self.grid[x + self.quarterCountX][y + self.quarterCountY].prepareUpdate()
////                }
////
////                DispatchQueue.concurrentPerform(iterations: self.quarterCountY) { y in
////                    self.grid[x + self.quarterCountX*2][y].prepareUpdate()
////                    self.grid[x][y + self.quarterCountY*2].prepareUpdate()
////                    self.grid[x + self.quarterCountX*2][y + self.quarterCountY*2].prepareUpdate()
////                }
////
////                DispatchQueue.concurrentPerform(iterations: self.quarterCountY) { y in
////                    self.grid[x + self.quarterCountX*3][y].prepareUpdate()
////                    self.grid[x][y + self.quarterCountY*3].prepareUpdate()
////                    self.grid[x + self.quarterCountX*3][y + self.quarterCountY*3].prepareUpdate()
////                }
////
////                DispatchQueue.concurrentPerform(iterations: self.quarterCountY) { y in
////                    self.grid[x + self.quarterCountX][y + self.quarterCountY*2].prepareUpdate()
////                    self.grid[x + self.quarterCountX*2][y + self.quarterCountY].prepareUpdate()
////                }
////
////                DispatchQueue.concurrentPerform(iterations: self.quarterCountY) { y in
////                    self.grid[x + self.quarterCountX][y + self.quarterCountY*3].prepareUpdate()
////                    self.grid[x + self.quarterCountX*3][y + self.quarterCountY].prepareUpdate()
////                }
////
////                DispatchQueue.concurrentPerform(iterations: self.quarterCountY) { y in
////                    self.grid[x + self.quarterCountX*3][y + self.quarterCountY*2].prepareUpdate()
////                    self.grid[x + self.quarterCountX*2][y + self.quarterCountY*3].prepareUpdate()
////                }
//
//                DispatchQueue.concurrentPerform(iterations: self.quarterCountY) { y in
//                    self.grid[x][y].prepareUpdate()
//
//                    self.grid[x + self.quarterCountX][y].prepareUpdate()
//                    self.grid[x][y + self.quarterCountY].prepareUpdate()
//                    self.grid[x + self.quarterCountX][y + self.quarterCountY].prepareUpdate()
//
//                    self.grid[x + self.quarterCountX*2][y].prepareUpdate()
//                    self.grid[x][y + self.quarterCountY*2].prepareUpdate()
//                    self.grid[x + self.quarterCountX*2][y + self.quarterCountY*2].prepareUpdate()
//
//                    self.grid[x + self.quarterCountX*3][y].prepareUpdate()
//                    self.grid[x][y + self.quarterCountY*3].prepareUpdate()
//                    self.grid[x + self.quarterCountX*3][y + self.quarterCountY*3].prepareUpdate()
//
//                    self.grid[x + self.quarterCountX][y + self.quarterCountY*2].prepareUpdate()
//                    self.grid[x + self.quarterCountX*2][y + self.quarterCountY].prepareUpdate()
//
//                    self.grid[x + self.quarterCountX][y + self.quarterCountY*3].prepareUpdate()
//                    self.grid[x + self.quarterCountX*3][y + self.quarterCountY].prepareUpdate()
//
//                    self.grid[x + self.quarterCountX*3][y + self.quarterCountY*2].prepareUpdate()
//                    self.grid[x + self.quarterCountX*2][y + self.quarterCountY*3].prepareUpdate()
//                }
//            }
//        }

        // Update
        // Doing concurrentPerform on both inner and outer loops doubles FPS:
        updateQueue.sync(flags: .barrier) {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                    self.grid[x][y].update()
                }
            }
        }
        
//        updateQueue.sync(flags: .barrier) {
//            DispatchQueue.concurrentPerform(iterations: self.quarterCountX) { x in
////                DispatchQueue.concurrentPerform(iterations: self.quarterCountY) { y in
////                    self.grid[x][y].update()
////
////                    self.grid[x + self.quarterCountX][y].update()
////                    self.grid[x][y + self.quarterCountY].update()
////                    self.grid[x + self.quarterCountX][y + self.quarterCountY].update()
////                }
////
////                DispatchQueue.concurrentPerform(iterations: self.quarterCountY) { y in
////                    self.grid[x + self.quarterCountX*2][y].update()
////                    self.grid[x][y + self.quarterCountY*2].update()
////                    self.grid[x + self.quarterCountX*2][y + self.quarterCountY*2].update()
////                }
////
////                DispatchQueue.concurrentPerform(iterations: self.quarterCountY) { y in
////                    self.grid[x + self.quarterCountX*3][y].update()
////                    self.grid[x][y + self.quarterCountY*3].update()
////                    self.grid[x + self.quarterCountX*3][y + self.quarterCountY*3].update()
////                }
////
////                DispatchQueue.concurrentPerform(iterations: self.quarterCountY) { y in
////                    self.grid[x + self.quarterCountX][y + self.quarterCountY*2].update()
////                    self.grid[x + self.quarterCountX*2][y + self.quarterCountY].update()
////                }
////
////                DispatchQueue.concurrentPerform(iterations: self.quarterCountY) { y in
////                    self.grid[x + self.quarterCountX][y + self.quarterCountY*3].update()
////                    self.grid[x + self.quarterCountX*3][y + self.quarterCountY].update()
////                }
////
////                DispatchQueue.concurrentPerform(iterations: self.quarterCountY) { y in
////                    self.grid[x + self.quarterCountX*3][y + self.quarterCountY*2].update()
////                    self.grid[x + self.quarterCountX*2][y + self.quarterCountY*3].update()
////                }
//
//                DispatchQueue.concurrentPerform(iterations: self.quarterCountY) { y in
//                    self.grid[x][y].update()
//
//                    self.grid[x + self.quarterCountX][y].update()
//                    self.grid[x][y + self.quarterCountY].update()
//                    self.grid[x + self.quarterCountX][y + self.quarterCountY].update()
//
//                    self.grid[x + self.quarterCountX*2][y].update()
//                    self.grid[x][y + self.quarterCountY*2].update()
//                    self.grid[x + self.quarterCountX*2][y + self.quarterCountY*2].update()
//
//                    self.grid[x + self.quarterCountX*3][y].update()
//                    self.grid[x][y + self.quarterCountY*3].update()
//                    self.grid[x + self.quarterCountX*3][y + self.quarterCountY*3].update()
//
//                    self.grid[x + self.quarterCountX][y + self.quarterCountY*2].update()
//                    self.grid[x + self.quarterCountX*2][y + self.quarterCountY].update()
//
//                    self.grid[x + self.quarterCountX][y + self.quarterCountY*3].update()
//                    self.grid[x + self.quarterCountX*3][y + self.quarterCountY].update()
//
//                    self.grid[x + self.quarterCountX*3][y + self.quarterCountY*2].update()
//                    self.grid[x + self.quarterCountX*2][y + self.quarterCountY*3].update()
//                }
//            }
//        }
        
        generation += 1
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
    func touchedCell(at: CGPoint, gameRunning: Bool, withAltAction: Bool = false) {
        // Find the cell that contains the touch point and make it live:
        //        let (x, y) = self.getGridIndicesFromPoint(at: at)
        
        let x = Int(at.x / cellSize)
        let y = Int(at.y / cellSize)

        let touchedCell = grid[x][y]
        if !withAltAction && !touchedCell.alive() {
            updateQueue.sync(flags: .barrier) {
                if gameRunning {
                    touchedCell.makeLive()
                } else {
                    touchedCell.makeLiveTouched()
                }
            }
        }
        
        if withAltAction && touchedCell.alive() {
            updateQueue.sync(flags: .barrier) {
                if gameRunning {
                    touchedCell.makeDead()
                } else {
                    touchedCell.makeDeadTouched()
                }
                
            }
        }
        
        // TODO: Implement this the O(1) way
        // For now will just be a loop:
//        let xLen = grid.count
//        let yLen = grid[0].count
//        for x in 0..<xLen {
//            for y in 0..<yLen {
//                let nthCell = grid[x][y]
//                if nthCell.frame.contains(at) {
//                    if !nthCell.alive {
//                        nthCell.makeLive()
//                    }
//
//                    // Break out of loop as we already found cell that contains the point:
//                    break
//                }
//            }
//        }
    }
    
    // To create spaceships:
    func createPattern(with points: [CGPoint]) {
        for p in points {
            let x = Int(p.x / cellSize)
            let y = Int(p.y / cellSize)

            let touchedCell = grid[x][y]
            touchedCell.makeLive()
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
            if !cell.alive() {
                cell.makeShadow()
                shadowed.append(cell)
            }
        }
    }
    
    func getPointDimensions() -> (CGFloat, CGFloat) {
        return (getPointWidth(), getPointHeight())
    }
    
    func getPointWidth() -> CGFloat {
        return CGFloat(grid.count) * cellSize
    }
    
    func getPointHeight() -> CGFloat {
        guard let gridY = grid.first else {
            return 0
        }
        
        return CGFloat(gridY.count) * cellSize
    }
    
    @inlinable
    @inline(__always)
    func reset() {
        // Reset the game to initial state with no cells alive:
        updateQueue.sync(flags: .barrier) {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                    self.grid[x][y].makeDead()
                }
            }
        }
        
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
    
    // TODO: Would be fun to randomize cell states as a starting condition,
    //       and see what happens.
    @inlinable
    @inline(__always)
    func randomState(liveProbability: Double) {
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
            }
        }
    }
    
    func makeAllLive() {
        updateQueue.sync {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                    self.grid[x][y].makeLive()
                }
            }
        }
    }
    
}
