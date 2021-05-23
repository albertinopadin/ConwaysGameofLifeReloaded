//
//  CellGrid.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 4/15/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import SpriteKit


final class CellGrid {
    var xCount = 0
    var yCount = 0
    var grid = ContiguousArray<ContiguousArray<Cell>>()   // 2D Array to hold the cells
    var liveNeighbors = [[Int]]()
    var cellSize: CGFloat = 23.0
    var generation: UInt64 = 0
    var spaceshipFactory: SpaceshipFactory?
    
    var shadowed = [Cell]()
    
    init(xCells: Int, yCells: Int, cellSize: CGFloat) {
        xCount = xCells
        yCount = yCells
        self.cellSize = cellSize
        grid = makeGrid(xCells: xCells, yCells: yCells)
        setNeighborsForAllCellsInGrid()
//        liveNeighbors = [[Int]](repeating: [Int](repeating: 0, count: yCount), count: xCount)
        spaceshipFactory = SpaceshipFactory(cellSize: cellSize)
    }
    
    func makeGrid(xCells: Int, yCells: Int) -> ContiguousArray<ContiguousArray<Cell>> {
        let initialCell = Cell(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        let newGridRow = ContiguousArray<Cell>(repeating: initialCell, count: yCells)
        var newGrid = ContiguousArray<ContiguousArray<Cell>>(repeating: newGridRow, count: xCells)
        for x in 0..<xCells {
            for y in 0..<yCells {
                // The x and y coords are not at the edge of the cell; instead they are the center of it.
                // This can create confusion when attempting to position cells!
                let cellFrame = CGRect(x: cellMiddle(iteration: x, length: cellSize),
                                       y: cellMiddle(iteration: y, length: cellSize),
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
    
    // Update cells using Conway's Rules of Life:
    // 1) Any live cell with fewer than two live neighbors dies (underpopulation)
    // 2) Any live cell with two or three live neighbors lives on to the next generation
    // 3) Any live cell with more than three live neighbors dies (overpopulation)
    // 4) Any dead cell with exactly three live neighbors becomes a live cell (reproduction)
    // Must apply changes all at once for each generation, so will need copy of current cell grid
    func updateCells() -> UInt64 {
        // Iterate through the current grid, updating the next gen grid accordingly:
        let xCount = grid.count
        let yCount = grid.first!.count
        updateLastGenLiveNeighbors()
        
        let _ = DispatchQueue.global(qos: .userInteractive)
        DispatchQueue.concurrentPerform(iterations: xCount) { x in
            for y in 0..<yCount {
                let cell = grid[x][y]
                let numberOfLiveNeighbors = cell.lastGenLiveNeighbors

                switch numberOfLiveNeighbors {
                case _ where numberOfLiveNeighbors < 2:
                    if cell.alive {
                        cell.makeDead()
                    }

                case 2:
                    break

                case 3:
                    if !cell.alive {
                        cell.makeLive()
                    }

                case _ where numberOfLiveNeighbors > 3:
                    if cell.alive {
                        cell.makeDead()
                    }

                default:
                    break
                }
            }
        }
        
        generation += 1
        return generation
    }
    
    func updateLiveNeighborsGrid() {
        for x in 0..<xCount {
            for y in 0..<yCount {
                let cell = grid[x][y]
                liveNeighbors[x][y] = cell.neighbors.filter({$0.alive}).count
            }
        }
    }
    
    func updateLastGenLiveNeighbors() {
        let _ = DispatchQueue.global(qos: .userInteractive)
        DispatchQueue.concurrentPerform(iterations: xCount) { x in
            for y in 0..<yCount {
                grid[x][y].updateLastGenLiveNeigbors()
            }
        }
    }
    
    func deepCopyCellArray(originalGrid: ContiguousArray<ContiguousArray<Cell>>) -> ContiguousArray<ContiguousArray<Cell>> {
        var copyGrid = ContiguousArray<ContiguousArray<Cell>>()
        // Need to find a fast way to deep copy array of objects;
        // For now will use for loop:
        for cellArray in originalGrid {
            copyGrid.append(ContiguousArray<Cell>())
            let cellRowIndex = copyGrid.count - 1
            
            // Deep copy of cell objects:
            for originalCell in cellArray {
                let copyCell = Cell(frame: originalCell.frame, alive: originalCell.alive, color: originalCell.color)
                var copyNeighbors = ContiguousArray<Cell>()
                for ogNeighbor in originalCell.neighbors {
                    copyNeighbors.append(Cell(frame: ogNeighbor.frame, alive: ogNeighbor.alive, color: ogNeighbor.color))
                }
                copyCell.neighbors = copyNeighbors
                copyGrid[cellRowIndex].append(copyCell)
            }
        }
        
        return copyGrid
    }

    func getGridIndicesFromPoint(at: CGPoint) -> (x: Int, y: Int) {
        let xIndex = Int(at.x / cellSize)
        let yIndex = Int(at.y / cellSize)
        
        return (xIndex, yIndex)
    }
        
    // TODO: Fix index out of bounds bug here:
    func touchedCell(at: CGPoint, withAltAction: Bool = false) {
        // Find the cell that contains the touch point and make it live:
        //        let (x, y) = self.getGridIndicesFromPoint(at: at)
        
        let x = Int(at.x / cellSize)
        let y = Int(at.y / cellSize)

        let touchedCell = grid[x][y]
        if !withAltAction && !touchedCell.alive {
            touchedCell.makeLive(touched: true)
        }
        
        if withAltAction && touchedCell.alive {
            touchedCell.makeDead(touched: true)
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
            cell.color = .blue
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
        return CGFloat(grid.count) * cellSize
    }
    
    func getPointHeight() -> CGFloat {
        guard let gridY = grid.first else {
            return 0
        }
        
        return CGFloat(gridY.count) * cellSize
    }
    
    func reset() {
        // Reset the game to initial state with no cells alive:
        if !self.grid.isEmpty {
            for cellArray in self.grid {
                for cell in cellArray {
                    cell.makeDead()
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
    
}
